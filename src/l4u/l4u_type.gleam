////let assert [Scope(tvars), ..] = closure_env.scopes

// latest
import gleam/list
import gleam/dict.{type Dict}
import gleam/string
import gleam/regex
import gleam/result
import gleam/int
import gleam/float
import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/order

@external(erlang, "l4u_ffi", "unsafe_corece")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "unsafe_corece")
pub fn unsafe_corece(value: a) -> b

@external(erlang, "l4u@sys_bridge_ffi", "to_native_dictionary")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "to_native_dictionary")
pub fn to_native_dictionary(xs: List(x)) -> any

@target(erlang)
pub fn native_undefined() -> any {
  Nil
  |> unsafe_corece
}

@target(erlang)
pub fn native_nil() -> any {
  Nil
  |> unsafe_corece
}

@target(erlang)
pub fn native_true() -> any {
  True
  |> unsafe_corece
}

@target(erlang)
pub fn native_false() -> any {
  False
  |> unsafe_corece
}

@target(javascript)
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "native_undefined")
pub fn native_undefined() -> any

@target(javascript)
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "native_nil")
pub fn native_nil() -> any

@target(javascript)
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "native_true")
pub fn native_true() -> any

@target(javascript)
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "native_false")
pub fn native_false() -> any

// ----------------------------------------------------------------------------
// # types
// ----------------------------------------------------------------------------

pub type PDic

pub type Ref

pub type ErrorEx {
  ErrorEx2(msg: String, detail: Dynamic)
}

pub type Info {
  Info(name: String, level: Int)
}

pub type Description {
  Description(name: String, text: String)
}

pub type Scope {
  Scope(bindings: Dict(String, Expr))
  ProcessDict(PDic)
}

pub type EnvOptions {
  EnvOptions(verbose: Bool, trace: Bool)
}

pub type EnvOption {
  VERBOSE
  TRACE
}

pub type Env {
  Env(
    info: Info,
    pdic: PDic,
    local_vars: Dict(String, Expr),
    a_binding: Dict(String, Expr),
    scopes: List(Scope),
    opts: EnvOptions,
  )
}

pub type Expr {
  PRINTABLE(Expr)
  UNDEFINED
  NIL
  TRUE
  FALSE
  DELIMITER
  WithEnv(Expr, Env)
  LocalContinuation(List(Expr), Env, Env)
  Continuation(List(Expr), Env)
  ATOM(Ref)
  INT(Int)
  FLOAT(Float)
  STRING(String)
  SYMBOL(String)
  ExVAR(String, String)
  KEYWORD(String)
  LIST(List(Expr))
  VECTOR(List(Expr))
  DICT(List(Expr))
  BIF(Description, fn(List(Expr), Env) -> Expr)
  BISPFORM(Description, fn(List(Expr), Env) -> Expr)

  CLOSURE(Description, List(String), List(Expr), Env)
  MACRO(Description, List(String), List(Expr), Env)

  WithMeta(Expr, Expr)
  NativeValue(String, Dynamic)
  NativeFunction(String, Dynamic)
  ReplCommand(String, Expr)
  CustomType(String, Expr)
  CustomTypeDef(String, Expr)
}

pub fn unbox_l4u(expr: Expr) -> any {
  case expr {
    PRINTABLE(x) -> unbox_l4u(x)
    UNDEFINED -> native_undefined()
    NIL -> native_nil()
    TRUE -> native_true()
    FALSE -> native_false()
    INT(x) -> unsafe_corece(x)
    FLOAT(x) -> unsafe_corece(x)
    STRING(x) -> unsafe_corece(x)
    SYMBOL(x) -> unsafe_corece(x)
    KEYWORD(x) -> unsafe_corece(x)
    LIST(xs) ->
      list.map(xs, unbox_l4u)
      |> unsafe_corece
    VECTOR(xs) ->
      list.map(xs, unbox_l4u)
      |> unsafe_corece
    DICT(xs) ->
      to_native_dictionary(list.map(xs, unbox_l4u))
      |> unsafe_corece
    NativeValue(_, x) -> unsafe_corece(x)
    NativeFunction(_, x) -> unsafe_corece(x)
    CustomType(_, x) -> unsafe_corece(x)
    //_ ->
    //  "unsupported conversion."
    //  |> unsafe_corece
    else_val -> unsafe_corece(else_val)
  }
}

pub fn box_l4u_int(x: Int) -> Expr {
  INT(x)
}

pub fn box_l4u_float(x: Float) -> Expr {
  FLOAT(x)
}

pub fn box_l4u_string(x: String) -> Expr {
  STRING(x)
}

pub fn box_l4u_symbol(x: String) -> Expr {
  SYMBOL(x)
}

pub fn box_l4u_keyword(x: String) -> Expr {
  KEYWORD(x)
}

pub fn box_l4u_list(x: List(Expr)) -> Expr {
  LIST(x)
}

pub fn box_l4u_vector(x: List(Expr)) -> Expr {
  VECTOR(x)
}

pub fn box_l4u_dict(x: List(Expr)) -> Expr {
  DICT(x)
}

pub fn box_l4u_native_value(name: String, x: Dynamic) -> Expr {
  NativeValue(name, x)
}

pub fn box_l4u_native_function(name: String, x: Dynamic) -> Expr {
  NativeFunction(name, x)
}

pub fn box_l4u_custom_type(name: String, x: Expr) -> Expr {
  CustomType(name, x)
}

pub fn box_l4u_custom_type_def(name: String, x: Expr) -> Expr {
  CustomTypeDef(name, x)
}

pub fn box_l4u_ok(x: any) -> Result(any, a) {
  Ok(x)
}
