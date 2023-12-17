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
@target(javascript)
import gleam/javascript/promise
import l4u/sys_bridge.{
  PDic, Pid, Ref, abspath, catch_ex, console_readline, console_writeln, dbgout1,
  dbgout2, dbgout3, deref, dir_exists, do_async, file_exists, get_cwd,
  internal_form, l4u_to_native, load_file, make_ref, native_to_l4u, os_cmd,
  process_dict_get, process_dict_keys, process_dict_set, reset_ref, set_cwd,
  throw_err, throw_expr, unsafe_corece,
}
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, DELIMITER, DICT, Description, Env,
  Expr, FALSE, FLOAT, INT, KEYWORD, LIST, MACRO, NIL, NativeFunction,
  NativeValue, STRING, SYMBOL, Scope, TRUE, UNDEFINED, VECTOR, WithEnv,
  description, env_set_global, env_set_local, eval, inspect, main as do_repl,
  make_new_l4u_core_env, print, pstr, show, to_l4u_bool, uneval,
}
import l4u/l4u_core as l4u

fn plist_get_value(plist: List(Expr), key: String) -> Option(Expr) {
  case plist {
    [] -> None
    [k, v, ..rest] -> {
      let str_k = pstr(k)
      case str_k == key {
        True -> Some(v)
        _ -> plist_get_value(rest, key)
      }
    }
    _ -> {
      throw_err("plist_get_value: plist is not a list of pairs")
      None
    }
  }
}

pub fn plist_get_str(plist: List(Expr), key: String) -> Option(String) {
  case plist_get_value(plist, key) {
    Some(x) -> Some(pstr(x))
    _ -> None
  }
}

pub fn plist_get_int(plist: List(Expr), key: String) -> Option(Int) {
  case plist_get_value(plist, key) {
    Some(INT(i)) -> Some(i)
    _ -> None
  }
}

pub fn plist_get_bool(plist: List(Expr), key: String) -> Option(Bool) {
  case plist_get_value(plist, key) {
    Some(TRUE) -> Some(True)
    Some(FALSE) -> Some(False)
    _ -> None
  }
}

pub fn plist_get_str_with_default(
  plist: List(Expr),
  key: String,
  default: String,
) -> String {
  case plist_get_str(plist, key) {
    Some(x) -> x
    _ -> default
  }
}

pub fn plist_get_int_with_default(
  plist: List(Expr),
  key: String,
  default: Int,
) -> Int {
  case plist_get_int(plist, key) {
    Some(x) -> x
    _ -> default
  }
}

pub fn plist_get_bool_with_default(
  plist: List(Expr),
  key: String,
  default: Bool,
) -> Bool {
  case plist_get_bool(plist, key) {
    Some(x) -> x
    _ -> default
  }
}
