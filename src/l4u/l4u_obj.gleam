import gleam/io
import gleam/list
import gleam/dict
import gleam/string
import gleam/regex
import gleam/result
import gleam/int
import gleam/float
import gleam/option
import gleam/order
import l4u/sys_bridge.{
  type Pid, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, deref, do_async, exec, internal_form, load_file, make_ref,
  new_process, reset_ref, throw_err, throw_expr, unique_pdic,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core as l4u
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, read, rep, repl, show,
  to_l4u_bool, tokenize, trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{
  type Env, type Expr, LIST, UNDEFINED, WithEnv, native_false, native_nil,
  native_true, native_undefined, to_native_dictionary, unsafe_corece,
}
import gleam_bridge

/// L4uobj is a type that can operate an object that keeps the condition like the so called object oriented language.
pub type L4uObj {
  L4uObj(
    /// Name of this L4uObj.
    name: String,
    /// PID of the process where EVAL is executed.
    pid: Pid,
    /// Get the current environment of the L4uObj. 
    get_env: fn() -> Env,
    /// Evaluate the given list of s-expressions in the environment
    eval: fn(List(Expr)) -> Result(Expr, String),
    /// Read the given string and return the list of s-expressions.
    read: fn(String) -> Result(List(Expr), String),
    /// Print the given s-expression and return the string representation.
    print: fn(Expr) -> String,
  )
}

@external(erlang, "l4u@process", "get_env")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "process_get_env")
pub fn process_get_env(pid: Pid) -> Env

pub fn generate_new_l4u_obj(name: String, initializer: fn() -> Env) -> L4uObj {
  let assert Ok(pid) = new_process(initializer)
  L4uObj(
    name: name,
    pid: pid,
    get_env: fn() -> Env { process_get_env(pid) },
    eval: fn(exprs: List(Expr)) -> Result(Expr, String) {
      //dbgout2("### l4u_obj: eval", exprs)
      let f = fn(env: Env) {
        //dbgout2("####### l4u_obj: eval: env", env)
        let assert WithEnv(rexpr, new_env) = eval(exprs, UNDEFINED, env)
      }
      case exec(pid, f) {
        Ok(expr) -> Ok(expr)
        //Error(err) -> Error("???err")
        Error(err) -> {
          //dbgout2("l4u_obj: eval: error", err)
          Error(err)
        }
      }
    },
    read: fn(s: String) -> Result(List(Expr), String) {
      let f = fn(env: Env) {
        //dbgout2("####### l4u_obj: read: ", s)
        let exprs = read(s, env)
        //dbgout2("####### l4u_obj: read: -> ", exprs)
        WithEnv(LIST(exprs), env)
      }
      case exec(pid, f) {
        Ok(LIST(rexprs)) -> Ok(rexprs)
        Error(err) -> Error(err)
        unhandable -> {
          throw_err("unhandable exec error in l4u_obj: read")
          Error("unhandable")
        }
      }
    },
    print: fn(expr: Expr) -> String { print(expr) },
  )
}
