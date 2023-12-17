import l4u/l4u
import gleam/list
import gleam/map.{Map}
import gleam/string
import l4u/l4u_core.{
  BIF, BISPFORM, Env, Expr, STRING, WithEnv, description, pstr,
}

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
  l4u.repl(l4uobj, "l4u> ")
}
