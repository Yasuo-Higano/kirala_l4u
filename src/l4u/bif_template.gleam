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
  type Env, type Expr, BIF, BISPFORM, DICT, NativeValue, STRING, WithEnv,
  native_false, native_nil, native_true, native_undefined, to_native_dictionary,
  unsafe_corece,
}
import l4u/l4u_core as l4u
import l4u/bbmustache_js as mustache
import l4u/bbmustache_js.{type Argument, string}

// (template-compile "Hello {{name}}!")
fn bif_template_compile(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(template)] = exprs

  let compiled = mustache.compile(template)

  WithEnv(NativeValue("bbmustache", dynamic.from(compiled)), env)
}

fn assoc_list_to_plist(
  assoc_list: List(Expr),
  acc: List(#(Expr, Expr)),
) -> List(#(Expr, Expr)) {
  case assoc_list {
    [] -> acc
    [key, value, ..rest] -> assoc_list_to_plist(rest, [#(key, value), ..acc])
    unhandable -> {
      throw_err("assoc_list_to_plist: unhandable pattern")
      []
    }
  }
}

// (k1 v1 k2 v2) -> [(k1 v1) (k2 v2)]
fn to_mustache_param(assoc_list: List(Expr)) -> List(#(String, Argument)) {
  let plist = assoc_list_to_plist(assoc_list, [])
  list.map(plist, fn(item) {
    let assert #(key, value) = item
    #(pstr(key), string(pstr(value)))
  })
}

// (template-render compiled-template {name: "world"})
fn bif_template_render(exprs: List(Expr), env: Env) -> Expr {
  let assert [NativeValue("bbmustache", compiled), DICT(assoc_list)] = exprs

  let rendered =
    mustache.render(unsafe_corece(compiled), to_mustache_param(assoc_list))

  WithEnv(STRING(rendered), env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_template_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    bif("template-compile", bif_template_compile),
    bif("template-render", bif_template_render),
  ]
}
