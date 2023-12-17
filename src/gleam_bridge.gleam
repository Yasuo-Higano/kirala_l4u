import gleam/list
import l4u/sys_bridge
@target(javascript)
import gleam/javascript/array
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, DELIMITER, DICT, Env, Expr, FALSE,
  FLOAT, INT, KEYWORD, LIST, MACRO, NIL, STRING, SYMBOL, Scope, TRUE, UNDEFINED,
  VECTOR, WithEnv, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, rep, repl,
  trace_set_last_funcall,
}

pub fn return_ok(value: any) -> Result(any, error) {
  Ok(value)
}

pub fn return_error(value: error) -> Result(any, error) {
  Error(value)
}

@target(javascript)
pub fn init() {
  let bridge = [#("return_ok", return_ok), #("return_error", return_error)]

  list.each(bridge, fn(i) {
    let #(key, value) = i
    l4u_sys_bridge.set_gleam_bridge(key, value)
  })

  //
  l4u_sys_bridge.set_gleam_bridge("array_to_list", array.to_list)
  l4u_sys_bridge.set_gleam_bridge("string_to_symbol", SYMBOL)
  l4u_sys_bridge.set_gleam_bridge("UNDEFINED", UNDEFINED)
  l4u_sys_bridge.set_gleam_bridge("TRUE", TRUE)
  l4u_sys_bridge.set_gleam_bridge("FALSE", FALSE)
  l4u_sys_bridge.set_gleam_bridge("NIL", NIL)
  True
}

@target(erlang)
pub fn init() {
  True
}
