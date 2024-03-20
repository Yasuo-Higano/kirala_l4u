import gleam/io
import gleam/list
import gleam/dict
import gleam/string
import gleam/regex
import gleam/result
import gleam/int
import gleam/float
import gleam/dynamic
import gleam/option
import gleam/order
import l4u/sys_bridge.{
  catch_ex, console_readline, console_writeln, dbgout1, dbgout2, dbgout3, deref,
  do_async, internal_form, l4u_to_native, load_file, make_ref, native_to_l4u,
  os_cmd, process_dict_get, process_dict_keys, process_dict_set, reset_ref,
  throw_err, throw_expr,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, rep, repl, show,
  to_l4u_bool, tokenize, trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{
  type Env, type Expr, BIF, BISPFORM, INT, STRING, WithEnv, native_false,
  native_nil, native_true, native_undefined, to_native_dictionary, unsafe_corece,
}
import l4u/l4u_core as l4u

@external(erlang, "l4u@bif_datetime_ffi", "start")
@external(javascript, "../l4u_bif_datetime_ffi.mjs", "start")
pub fn start() -> Nil

@external(erlang, "l4u@bif_datetime_ffi", "epoch")
@external(javascript, "../l4u_bif_datetime_ffi.mjs", "epoch")
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
@external(javascript, "../l4u_bif_datetime_ffi.mjs", "datetime_format")
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
