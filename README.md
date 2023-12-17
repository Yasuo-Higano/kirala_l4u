# Kirala L4u(Lisp for You) for Gleam language
- Kirara is Japanese for "gleam" feeling word in English.

L4u is a embedded lisp interpreter for use in gleam/erlang and gleam/javascript products.

This is still under construction and may undergo destructive changes.
It is intended to work with both gleam/erlang and gleam/javascript.
Currently it is only confirmed to work with erlang. The javascript version is in the works because gleam javascript is no longer working in my current Gleam environment.

It is roughly compatible with MAL (Make A Lisp).
Although this is a different implementation from the standard MAL method, it should be lisp compatible, so the following page should be helpful.
https://github.com/kanaka/mal

It is a very techy rough performance evaluation,
In the benchmark (tarai 12 6 0), I compared it with MAL's impls/c,erlang,elixir,python,ruby,
- c unable to complete due to segmentation fault
- erlang failed to complete(too many procecces)
- elixir failed to complete(too many procecces)
- 7 to 15 times faster than python
- 2 to 4 times faster than ruby
I think this implementation is not so bad.


## embedding sample

src/examples/test_l4u.gleam
```
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

```

```
$ gleam shell
Erlang/OTP 26 [erts-14.0.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]

Eshell V14.0.2 (press Ctrl+G to abort, type help(). for help)
1> examples@l4u@test_l4u:main().
Creating qdate ETS Table: qdate_srv
- init default0.lisp
- init default1.lisp
- init prelude.lisp
|0.87.0|main|l4u> (hello_fn "alpha" :beta 'gamma (+ 10 20))
"Hello, alpha, beta, gamma, 30!!"
|0.87.0|main|l4u> (hello_special_form "alpha" :beta 'gamma (+ 10 20))
"Hello, alpha, beta, quote gamma, + 10 20!!"
```

## import and call native module/functions

```
; (import-native-module MODULE_NAME ALIAS)
; All of the following will work the same.
(import-native-module [:examples :l4u :test_l4u] :test-l4u)
; (import-native-module '[examples l4u test_l4u] :test-l4u)
; (import-native-module '[examples@l4u@test_l4u] :test-l4u)

; (global-keys) retrieves the keys of all variables bound to the global region. It is also possible to filter by forward matching strings as follows
(global-keys :test)

; Call the function and start the REPL the same way you did in erlang.
(test_l4u:main)
```