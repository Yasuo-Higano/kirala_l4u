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

@external(erlang, "l4u@bif_datetime_ffi", "start")
pub fn start() -> Nil

@external(erlang, "l4u@bif_datetime_ffi", "epoch")
pub fn epoch() -> Int

// (now)
fn bif_now(exprs: List(Expr), env: Env) -> Expr {
  let assert [] = exprs
  //let timestamp32 = float.round(now())
  let timestamp32 = epoch()
  WithEnv(INT(timestamp32), env)
}

// (datetime-format (now) "Y-m-d H:m:s")
@external(erlang, "l4u@bif_datetime_ffi", "datetime_format")
pub fn datetime_format(timestamp: Int, format: String) -> String

// (datetime-format timestamp "Y-m-d H:m:s")
fn bif_datetime_format(exprs: List(Expr), env: Env) -> Expr {
  let assert [INT(timestamp), format] = exprs
  let str_format = pstr(format)

  let formatted = datetime_format(timestamp, str_format)

  WithEnv(STRING(formatted), env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_datetime_def() -> List(#(String, Expr)) {
  start()
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    // datetime
    //bif("time-ms", bif_time_ms),
    bif("now", bif_now),
    bif("datetime-format", bif_datetime_format),
  ]
  //bif("datetime", bif_datetime),
  //bif("datetime-parse", bif_datetime_parse),
  //bif("duration", bif_duration),
  //bif("datetime-components", bif_datetime_components),
}
