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
  abspath, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, deref, dir_exists, do_async, file_exists, get_cwd, internal_form,
  l4u_to_native, load_file, make_ref, native_to_l4u, os_cmd, process_dict_get,
  process_dict_keys, process_dict_set, reset_ref, set_cwd, throw_err, throw_expr,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, rep, repl, show,
  to_l4u_bool, tokenize, trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{
  type Env, type Expr, BIF, BISPFORM, LIST, TRUE, WithEnv, native_false,
  native_nil, native_true, native_undefined, to_native_dictionary, unsafe_corece,
}
import l4u/l4u_core as l4u
import l4u/plist.{
  plist_get_bool, plist_get_bool_with_default, plist_get_int,
  plist_get_int_with_default, plist_get_str, plist_get_str_with_default,
}

// (file-exists? "foo.txt") -> true / false
fn bif_file_exists(exprs: List(Expr), env: Env) -> Expr {
  let assert [path] = exprs
  let str_path = pstr(uneval(path))
  let exists = file_exists(str_path)
  WithEnv(native_to_l4u(unsafe_corece(exists)), env)
}

// (dir-exists? "foo") -> true / false
fn bif_dir_exists(exprs: List(Expr), env: Env) -> Expr {
  let assert [path] = exprs
  let str_path = pstr(uneval(path))
  let exists = dir_exists(str_path)
  WithEnv(native_to_l4u(unsafe_corece(exists)), env)
}

// (get-cwd) -> "foo"
fn bif_get_cwd(exprs: List(Expr), env: Env) -> Expr {
  let assert [] = exprs
  let cwd = get_cwd()
  WithEnv(native_to_l4u(unsafe_corece(cwd)), env)
}

// (set-cwd "foo") -> "foo"
fn bif_set_cwd(exprs: List(Expr), env: Env) -> Expr {
  let assert [path] = exprs
  let str_path = pstr(uneval(path))
  set_cwd(str_path)
  WithEnv(TRUE, env)
}

// (abspath "foo") -> "/dir/foo"
fn bif_abspath(exprs: List(Expr), env: Env) -> Expr {
  let assert [path] = exprs
  let str_path = pstr(uneval(path))
  let abs_path = abspath(str_path)
  WithEnv(native_to_l4u(unsafe_corece(abs_path)), env)
}

@external(erlang, "l4u@bif_file_ffi", "scan_directory")
@external(javascript, "../l4u_bif_file_ffi.mjs", "scan_directory")
pub fn scan_directory(path: String, max_depth: Int) -> List(String)

// (dir-scar PATH)
// (dir-scar PATH [:max-depth 1])
fn bif_dir_scan(exprs: List(Expr), env: Env) -> Expr {
  let #(str_path, max_depth) = case exprs {
    [path] -> #(pstr(uneval(path)), 9999)
    [path, params] -> {
      let assert LIST(params) = uneval(params)
      #(
        pstr(uneval(path)),
        plist_get_int_with_default(params, "max-depth", 9999),
      )
    }
    unhandable -> {
      throw_expr("dir-scan: unhandable exprs")
      #("unhandable", -1)
    }
  }
  let files = scan_directory(str_path, max_depth)
  let l4u_files = list.map(files, fn(f) { native_to_l4u(unsafe_corece(f)) })
  WithEnv(LIST(l4u_files), env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_file_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    bif("file-exists?", bif_file_exists),
    bif("dir-exists?", bif_dir_exists),
    bif("dir-scan", bif_dir_scan),
    bif("get-cwd", bif_get_cwd),
    bif("set-cwd", bif_set_cwd),
    bif("abspath", bif_abspath),
  ]
}
