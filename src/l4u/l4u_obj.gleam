import gleam/io
import gleam/list
import gleam/map.{Map}
import gleam/string
import gleam/regex.{Regex}
import gleam/result
import gleam/int
import gleam/float
import gleam/option.{None, Option, Some}
import gleam/order.{Eq, Gt, Lt, Order}
import l4u/sys_bridge.{
  Pid, Ref, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, deref, do_async, exec, internal_form, load_file, make_ref,
  new_process, reset_ref, throw_err, throw_expr, unique_pdic,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core as l4u
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, DELIMITER, DICT, Env, Expr, FALSE,
  FLOAT, INT, KEYWORD, LIST, MACRO, NIL, STRING, SYMBOL, Scope, TRUE, UNDEFINED,
  VECTOR, WithEnv, env_set_global, env_set_local, eval, inspect, main as do_repl,
  make_new_l4u_core_env, print, pstr, read,
}
import gleam_bridge

pub type L4uObj {
  L4uObj(
    name: String,
    pid: Pid,
    get_env: fn() -> Env,
    eval: fn(List(Expr)) -> Result(Expr, String),
    read: fn(String) -> Result(List(Expr), String),
    print: fn(Expr) -> String,
  )
}

@external(erlang, "l4u@process", "get_env")
pub fn process_get_env(pid: Pid) -> Env

pub fn generate_new_l4u_obj(name: String, initializer: fn() -> Env) -> L4uObj {
  let assert Ok(pid) = new_process(initializer)
  L4uObj(
    name: name,
    pid: pid,
    get_env: fn() -> Env { process_get_env(pid) },
    eval: fn(exprs: List(Expr)) -> Result(Expr, String) {
      //dbgout2("l4u_obj: eval", exprs)
      let f = fn(env: Env) {
        let assert WithEnv(rexpr, new_env) = eval(exprs, UNDEFINED, env)
      }
      case exec(pid, f) {
        Ok(expr) -> Ok(expr)
        //Error(err) -> Error("???err")
        Error(err) -> Error(err)
      }
    },
    read: fn(s: String) -> Result(List(Expr), String) {
      let f = fn(env: Env) {
        let exprs = read(s, env)
        WithEnv(LIST(exprs), env)
      }
      case exec(pid, f) {
        Ok(LIST(rexprs)) -> Ok(rexprs)
        Error(err) -> Error(err)
      }
    },
    print: fn(expr: Expr) -> String { print(expr) },
  )
}
