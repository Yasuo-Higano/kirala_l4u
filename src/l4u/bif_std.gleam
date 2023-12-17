import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/string
import gleam/regex.{Regex}
import gleam/result
import gleam/int
import gleam/float
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/order.{Eq, Gt, Lt, Order}
import l4u/sys_bridge.{
  PDic, Pid, Ref, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, deref, do_async, escape_binary_string, internal_form, l4u_to_native,
  load_file, make_ref, native_to_l4u, os_cmd, process_dict_get,
  process_dict_keys, process_dict_set, reset_ref, throw_err, throw_expr,
  unescape_binary_string, unique_int, unsafe_corece,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, DELIMITER, DICT, Description, Env,
  Expr, FALSE, FLOAT, INT, KEYWORD, LIST, MACRO, NIL, NativeFunction,
  NativeValue, STRING, SYMBOL, Scope, TRUE, UNDEFINED, VECTOR, WithEnv,
  description, env_set_global, env_set_local, eval, inspect, main as do_repl,
  make_new_l4u_core_env, print, pstr, show, tokenize, uneval,
}
import l4u/l4u_core as l4u

// ----------------------------------------------------------------------------
// # library
// ----------------------------------------------------------------------------

// (unique-int)
fn bif_unique_int(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(INT(unique_int()), env)
}

// ---------------------------------------------------------------------------
// # convert
// ---------------------------------------------------------------------------

// (int Expr)
fn bif_int(exprs: List(Expr), env: Env) -> Expr {
  let rexpr = case exprs {
    [INT(val) as expr] -> expr
    [FLOAT(val)] -> INT(float.truncate(val))
    [x] ->
      INT(
        int.parse(pstr(x))
        |> result.unwrap(0),
      )
  }
  WithEnv(rexpr, env)
}

// (float Expr)
fn bif_float(exprs: List(Expr), env: Env) -> Expr {
  let rexpr = case exprs {
    [FLOAT(val) as expr] -> expr
    [INT(val)] -> FLOAT(int.to_float(val))
    [x] ->
      FLOAT(
        float.parse(pstr(x))
        |> result.unwrap(0.0),
      )
  }
  WithEnv(rexpr, env)
}

// (string Expr Delimiter)
fn bif_string(exprs: List(Expr), env: Env) -> Expr {
  let #(vals, delimiter) = case exprs {
    [vals] -> #(uneval(vals), "")
    [vals, delimiter] -> #(uneval(vals), pstr(delimiter))
  }
  case vals {
    LIST(vals) -> {
      let str =
        list.map(exprs, fn(expr) { pstr(expr) })
        |> string.join("")
      WithEnv(STRING(str), env)
    }
    x -> WithEnv(STRING(pstr(x)), env)
  }
}

// ---------------------------------------------------------------------------
// #
// ---------------------------------------------------------------------------

// (assert Expr)
fn bif_assert(exprs: List(Expr), env: Env) -> Expr {
  let WithEnv(eexpr, renv) = eval(exprs, UNDEFINED, env)
  case eexpr {
    TRUE -> TRUE
    _ -> {
      throw_expr(exprs)
      FALSE
    }
  }
  WithEnv(TRUE, env)
}

// (tokenize Expr)
fn bif_tokenize(exprs: List(Expr), env: Env) -> Expr {
  let [STRING(val)] = exprs

  let rexpr = list.map(tokenize(val, env), fn(x) { STRING(x) })

  WithEnv(LIST(rexpr), env)
}

@external(erlang, "l4u@bif_std_ffi", "json_format")
fn json_format(expr: Expr) -> String

// (json-format Expr) -> STRING
fn bif_json_format(exprs: List(Expr), env: Env) -> Expr {
  let [expr] = exprs
  let rexpr = uneval(expr)
  WithEnv(STRING(json_format(rexpr)), env)
}

@external(erlang, "l4u@bif_std_ffi", "json_parse")
fn json_parse(val: String) -> Expr

// (json-parse STRING) -> Expr
fn bif_json_parse(exprs: List(Expr), env: Env) -> Expr {
  let [STRING(val)] = exprs
  let rexpr = json_parse(val)
  WithEnv(rexpr, env)
}

// (escape STRING) -> STRING
fn bif_escape(exprs: List(Expr), env: Env) -> Expr {
  let [STRING(val)] = exprs
  let rexpr = escape_binary_string(val)
  WithEnv(STRING(rexpr), env)
}

// (unescape STRING) -> STRING
fn bif_unescape(exprs: List(Expr), env: Env) -> Expr {
  let [STRING(val)] = exprs
  let rexpr = unescape_binary_string(val)
  WithEnv(STRING(rexpr), env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_std_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    //bif("pr-str", bif_pr_str),
    bif("unique-int", bif_unique_int),
    // convert
    bif("int", bif_int),
    bif("float", bif_float),
    bif("string", bif_string),
    //
    bsf("assert", bif_assert),
    bif("tokenize", bif_tokenize),
    bif("json-format", bif_json_format),
    bif("json-parse", bif_json_parse),
    bif("escape", bif_escape),
    bif("unescape", bif_unescape),
  ]
}
