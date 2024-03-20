import l4u/l4u
import gleam/list
import gleam/dict
import gleam/string
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, read, rep, repl,
  repl_print, show, to_l4u_bool, tokenize, trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{type Env, type Expr, BIF, BISPFORM, STRING, WithEnv}

fn bif_hello(exprs: List(Expr), env: Env) -> Expr {
  let names =
    list.map(exprs, fn(e) { pstr(e) })
    |> string.join(", ")
  let message = "Hello, " <> names <> "!!"
  WithEnv(STRING(message), env)
}

fn bsf_hello_special_form(exprs: List(Expr), env: Env) -> Expr {
  let names =
    list.map(exprs, fn(e) { pstr(e) })
    |> string.join(", ")
  let message = "Hello, " <> names <> "!!"
  WithEnv(STRING(message), env)
}

pub fn main() {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }
  let defs = [
    bif("hello_fn", bif_hello),
    bsf("hello_special_form", bsf_hello_special_form),
  ]

  let l4uobj = l4u.start_and_generate_main_l4u(defs)
  l4u.l4u_repl(l4uobj, "l4u> ")
}
