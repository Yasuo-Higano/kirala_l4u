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
  dbgout3, deref, do_async, internal_form, l4u_to_native, load_file, make_ref,
  native_to_l4u, os_cmd, process_dict_get, process_dict_keys, process_dict_set,
  reset_ref, throw_err, throw_expr, unsafe_corece,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, DELIMITER, DICT, Description, Env,
  Expr, FALSE, FLOAT, INT, KEYWORD, LIST, MACRO, NIL, NativeFunction,
  NativeValue, STRING, SYMBOL, Scope, TRUE, UNDEFINED, VECTOR, WithEnv,
  description, env_set_global, env_set_local, eval, inspect, main as do_repl,
  make_new_l4u_core_env, print, pstr, show, to_l4u_bool, uneval,
}
import l4u/l4u_core as l4u

// (string-split "a,b,c" ",") => ["a" "b" "c"]
fn bif_string_split(exprs: List(Expr), env: Env) -> Expr {
  let retexpr = case exprs {
    [STRING(s), STRING(d)] -> {
      LIST(
        string.split(s, d)
        |> list.map(STRING),
      )
    }
    _ -> {
      throw_err("str-split: wrong number of arguments")
      UNDEFINED
    }
  }
  WithEnv(retexpr, env)
}

// (string-join ["a" "b" "c"] ",") => "a,b,c"
fn bif_string_join(exprs: List(Expr), env: Env) -> Expr {
  let assert [LIST(src), STRING(u)] = exprs
  WithEnv(STRING(string.join(list.map(src, fn(x) { show(x) }), u)), env)
}

// (string-replace "a,b,c" "," "-") => "a-b-c"
fn bif_string_replace(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), STRING(u), STRING(v)] = exprs
  WithEnv(STRING(string.replace(src, u, v)), env)
}

// (string-find "a,b,c" ",") => 1
fn bif_string_find(exprs: List(Expr), env: Env) -> Expr {
  todo
}

// (string-substring "a,b,c" 2 4) => "b,"
fn bif_string_substring(exprs: List(Expr), env: Env) -> Expr {
  todo
}

// (string-length "a,b,c") => 5
fn bif_string_length(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  WithEnv(INT(string.length(src)), env)
}

// (string-lower "Alpha,Beta,Gamma") => "alpha,beta,gamma"
fn bif_string_lower(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  WithEnv(STRING(string.lowercase(src)), env)
}

// (string-upper "Alpha,Beta,Gamma") => "ALPHA,BETA,GAMMA"
fn bif_string_upper(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  WithEnv(STRING(string.uppercase(src)), env)
}

// (string-trim "  abc  ") => "abc"
fn bif_string_trim(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  WithEnv(STRING(string.trim(src)), env)
}

// (string-starts-with "abc" "a") => true
fn bif_string_starts_with(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), STRING(u)] = exprs
  WithEnv(to_l4u_bool(string.starts_with(src, u)), env)
}

// (string-ends-with "abc" "c") => true
fn bif_string_ends_with(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), STRING(u)] = exprs
  WithEnv(to_l4u_bool(string.ends_with(src, u)), env)
}

// (string-contains "abc" "b") => true
fn bif_string_contains(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), STRING(u)] = exprs
  WithEnv(to_l4u_bool(string.contains(src, u)), env)
}

// (string-reverse "abc") => "cba"
fn bif_string_reverse(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  WithEnv(STRING(string.reverse(src)), env)
}

// (string-repeat "abc" 3) => "abcabcabc"
fn bif_string_repeat(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), INT(u)] = exprs
  WithEnv(STRING(string.repeat(src, u)), env)
}

// (string-pad-left "abc" 5) => "  abc"
fn bif_string_pad_left(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), INT(u), STRING(v)] = exprs
  WithEnv(STRING(string.pad_left(src, u, v)), env)
}

// (string-pad-right "abc" 5) => "abc  "
fn bif_string_pad_right(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), INT(u), STRING(v)] = exprs
  WithEnv(STRING(string.pad_right(src, u, v)), env)
}

// (string-replace-all "abcabcabc" "a" "x") => "xbcxbcxbc"
fn bif_string_replace_all(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src), STRING(u), STRING(v)] = exprs
  WithEnv(STRING(string.replace(src, u, v)), env)
}

// (string-replace-first "abcabcabc" "a" "x") => "xbcabcabc"
fn bif_string_replace_first(exprs: List(Expr), env: Env) -> Expr {
  todo
}

// (string-replace-range "abcabcabc" 1 3 "x") => "axcabcabc"
fn bif_string_replace_range(exprs: List(Expr), env: Env) -> Expr {
  todo
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_string_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    bif("string-split", bif_string_split),
    bif("string-join", bif_string_join),
    bif("string-replace", bif_string_replace),
    bif("string-find", bif_string_find),
    bif("string-substring", bif_string_substring),
    bif("string-length", bif_string_length),
    bif("string-lower", bif_string_lower),
    bif("string-upper", bif_string_upper),
    bif("string-trim", bif_string_trim),
    bif("string-starts-with?", bif_string_starts_with),
    bif("string-ends-with?", bif_string_ends_with),
    bif("string-contains", bif_string_contains),
    bif("string-reverse", bif_string_reverse),
    bif("string-repeat", bif_string_repeat),
    bif("string-pad-left", bif_string_pad_left),
    bif("string-pad-right", bif_string_pad_right),
    bif("string-replace-all", bif_string_replace_all),
    bif("string-replace-first", bif_string_replace_first),
    bif("string-replace-range", bif_string_replace_range),
  ]
}
