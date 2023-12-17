import gleam/io
import gleam/list
import gleam/dynamic
import gleam/map.{Map}
import gleam/string
import gleam/regex.{Regex}
import gleam/result
import gleam/int
import gleam/float
import gleam/option.{None, Option, Some}
import gleam/order.{Eq, Gt, Lt, Order}
import l4u/sys_bridge.{
  PDic, Pid, Ref, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, dbgout4, deref, do_async, error_to_string, escape_binary_string, exec,
  exec_native, internal_form, load_file, make_ref, new_process, process_dict_get,
  process_dict_set, reset_ref, stringify, throw_err, throw_expr, tick_count,
  to_string, unescape_binary_string, unique_int, unique_str, unsafe_corece,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  ATOM, BIF, BISPFORM, CLOSURE, Continuation, CustomType, DELIMITER, DICT,
  Description, Env, Expr, FALSE, FLOAT, INT, KEYWORD, LIST, MACRO, NIL,
  NativeValue, PRINTABLE, ReplCommand, STRING, SYMBOL, Scope, TRUE, UNDEFINED,
  VECTOR, WithEnv, description, dump_env, env_set_global, env_set_local, eval,
  inspect, main as do_repl, make_new_l4u_core_env, print, pstr, read, repl_print,
  show, trace_set_last_funcall, uneval,
}
import l4u/l4u_core as l4u
import l4u/bif_lib.{bif_lib_def}
import l4u/bif_string.{bif_string_def}
import l4u/bif_file.{bif_file_def}
import gleam_bridge
import l4u/global
import l4u/l4u_obj.{L4uObj}
import l4u/bif_std.{bif_std_def}
import l4u/bif_datetime.{bif_datetime_def}

const gdb__ = False

// (bindf (a (b (c d))) '(1 (2 (3 4))))
pub fn bispform_bindf(exprs: List(Expr), env: Env) -> Expr {
  let assert [bind_to, bind_from] = exprs
  let assert WithEnv(evalue, new_env) = eval([bind_from], UNDEFINED, env)
  WithEnv(UNDEFINED, bindf(bind_to, evalue, new_env))
}

fn bindf(bind_to: Expr, bind_from: Expr, env: Env) -> Env {
  //dbgout4("bindf: ", inspect(bind_to), " <- ", inspect(bind_from))
  let bind_from = uneval(bind_from)

  case uneval(bind_to) {
    CustomType(name, data) -> {
      //dbgout2("bindf: CustomType: ", name)
      let assert CustomType(name2, data2) = bind_from
      case name == name2 {
        True -> bindf(data, data2, env)
        False -> {
          throw_err(
            "bindf: custom type name not match: " <> name <> " != " <> name2,
          )
          env
        }
      }
    }
    LIST([SYMBOL("custom-type"), name, data]) -> {
      let name = pstr(name)
      //dbgout2("bindf: CustomType2: ", name)
      let assert CustomType(name2, data2) = bind_from
      case name == name2 {
        True -> bindf(data, data2, env)
        False -> {
          throw_err(
            "bindf: custom type name not match: " <> name <> " != " <> name2,
          )
          env
        }
      }
    }
    SYMBOL(name) -> {
      let new_env = env_set_local(env, name, bind_from)
    }
    LIST([]) -> {
      case bind_from {
        LIST([]) -> env
        _ -> {
          throw_err("bindf: empty list != bind_from")
          env
        }
      }
    }
    LIST([SYMBOL("quote"), x]) -> {
      case x == bind_from {
        True -> env
        False -> {
          throw_err("bindf: quoted bind_to != bind_from")
          env
        }
      }
    }
    LIST([bind_to, ..rest_bind_to]) -> {
      let assert LIST([bind_from, ..rest_bind_from]) = uneval(bind_from)
      let new_env = bindf(bind_to, bind_from, env)
      bindf(LIST(rest_bind_to), LIST(rest_bind_from), new_env)
    }
    _ -> {
      //dbgout4("bindf: else ", inspect(bind_to), " <- ", inspect(bind_from))
      case bind_to == bind_from {
        True -> env
        False -> {
          throw_err("bindf: bind_to != bind_from")
          env
        }
      }
    }
  }
}

// (case VALUE (PATTERN1 EXPR1...) (PATTERN2 EXPR2...) ...)
fn case_(value: Expr, cases: List(Expr), env: Env) -> Expr {
  //dbgout2("case: value: ", inspect(value))
  case cases {
    [] -> {
      throw_err("case: empty cases")
      WithEnv(UNDEFINED, env)
    }
    [VECTOR([pattern, ..body]), ..rest_cases]
    | [LIST([pattern, ..body]), ..rest_cases] -> {
      let bind_result = catch_ex(fn() { bindf(pattern, value, env) })
      //dbgout4("case: bind: ", inspect(pattern), " = ", inspect(value))
      case bind_result {
        Ok(new_env) -> {
          let assert WithEnv(result, new_env) = eval(body, UNDEFINED, new_env)
        }
        Error(_) -> {
          case_(value, rest_cases, env)
        }
      }
    }
    _ -> {
      throw_err("case: invalid cases")
      WithEnv(UNDEFINED, env)
    }
  }
}

pub fn bispform_case(exprs: List(Expr), env: Env) -> Expr {
  let assert [value, ..cases] = exprs
  let assert WithEnv(evalue, new_env) = eval([value], UNDEFINED, env)
  case_(evalue, cases, new_env)
}

// (cond (CONDITION1 EXPR1...) (CONDITION2 EXPR2...) ...)
fn cond_(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [] -> {
      throw_err("cond: empty exprs")
      WithEnv(UNDEFINED, env)
    }
    [LIST([condition, ..rest])] -> {
      let assert WithEnv(result, new_env) = eval([condition], UNDEFINED, env)
      case l4u.is_true_condition(result) {
        True -> {
          let assert WithEnv(result, new_env) = eval(rest, UNDEFINED, new_env)
          WithEnv(result, new_env)
        }
        False -> {
          cond_(exprs, new_env)
        }
      }
    }
    _ -> {
      throw_err("cond: invalid exprs")
      WithEnv(UNDEFINED, env)
    }
  }
}

pub fn bispform_cond(exprs: List(Expr), env: Env) -> Expr {
  cond_(exprs, env)
}

// ----------------------------------------------------------------------------
fn bif_unwrap_ok(exprs: List(Expr), env: Env) -> Expr {
  let expr = case exprs {
    [NativeValue(_name, value)] -> {
      NativeValue("", dynamic.from(Ok(value)))
    }
    _ -> NIL
  }
  WithEnv(expr, env)
}

// (native-value name value)
fn bif_native_value(exprs: List(Expr), env: Env) -> Expr {
  let assert [name, value] = exprs
  WithEnv(NativeValue(show(name), dynamic.from(value)), env)
}

fn bif_l4u_processes(exprs: List(Expr), env: Env) -> Expr {
  let assert dict = global.get_map("*l4u_processes*")
  let assert keys = map.keys(dict)
  WithEnv(LIST(list.map(keys, STRING)), env)
}

// ----------------------------------------------------------------------------

// (spawn name)
fn bif_spawn(exprs: List(Expr), env: Env) -> Expr {
  let name = case exprs {
    [name] -> show(name)
    _ -> unique_str()
  }
  let #(l4u, expr_l4u) = generate_l4u_process(name, [])
  WithEnv(expr_l4u, env)
}

fn bif_repl_switch(exprs: List(Expr), env: Env) -> Expr {
  let assert [name] = exprs
  let name = show(name)
  let assert l4u = global.get_map_value("*l4u_processes*", name, UNDEFINED)
  ReplCommand("repl-switch", l4u)
}

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "l4u@erlang_bifs", "erlang_bifs")
fn native_bifs() -> List(#(String, Expr))

@target(javascript)
@external(javascript, "../l4u_javascript_bifs.mjs", "js_bifs")
fn native_bifs() -> List(#(String, Expr))

pub fn make_new_l4u_env(
  additional_defs: List(#(String, Expr)),
  additional_files: List(String),
) -> Env {
  let pdic: PDic = unsafe_corece(unique_int())

  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  // bif table
  let defs = [
    bsf("bindf", bispform_bindf),
    bsf("case*", bispform_case),
    bsf("cond*", bispform_cond),
    //
    bif("unwrap-ok", bif_unwrap_ok),
    bif("native-value", bif_native_value),
    bif("l4u-processes", bif_l4u_processes),
    bif("spawn", bif_spawn),
    bif("repl-switch", bif_repl_switch),
  ]

  let files = []
  make_new_l4u_core_env(
    pdic,
    list.concat([
      defs,
      native_bifs(),
      bif_lib_def(),
      bif_string_def(),
      bif_file_def(),
      bif_std_def(),
      bif_datetime_def(),
      additional_defs,
    ]),
    list.append(files, additional_files),
  )
}

// ----------------------------------------------------------------------------
// # L4u Object
// ----------------------------------------------------------------------------

pub fn generate_l4u_process(
  name: String,
  additional_defs: List(#(String, Expr)),
) -> #(L4uObj, Expr) {
  let initializer = fn() {
    make_new_l4u_env(additional_defs, [])
    |> env_set_global(
      "*ARGV*",
      LIST(list.map(sys_bridge.get_command_line_args(), fn(x) { STRING(x) })),
    )
  }

  let l4u = l4u_obj.generate_new_l4u_obj(name, initializer)

  let expr_l4u = NativeValue("l4u", dynamic.from(l4u))
  global.set_map_value("*l4u_processes*", name, dynamic.from(expr_l4u))
  #(l4u, expr_l4u)
}

pub fn l4u_eval(l4u: L4uObj, exprs: List(Expr)) -> Expr {
  let assert Ok(rexpr) = l4u.eval(exprs)
  rexpr
}

pub fn l4u_read_eval(l4u: L4uObj, src: String) -> Result(Expr, String) {
  let assert Ok(exprs) = l4u.read(src)
  l4u.eval(exprs)
}

pub fn l4u_add_defs(
  l4u: L4uObj,
  defs: List(#(String, Expr)),
) -> Result(Expr, err) {
  let f = fn(env: Env) {
    list.map(defs, fn(item) {
      let #(k, v) = item
      dbgout4("l4u_add_defs: ", k, " = ", inspect(v))
      process_dict_set(l4u.get_env().pdic, k, v)
      dbgout2("verify: ", process_dict_get(l4u.get_env().pdic, k))
    })
    WithEnv(NIL, env)
  }
  let result = sys_bridge.exec(l4u.pid, f)
  result
}

pub fn l4u_get_main_process() -> L4uObj {
  global.get("*main-l4u*")
  |> unsafe_corece
}

pub fn l4u_get_process(name: String) -> Result(L4uObj, String) {
  case global.get(name) {
    UNDEFINED -> Error("l4u_get_process: not found")
    l4u -> Ok(unsafe_corece(l4u))
  }
}

// ----------------------------------------------------------------------------
// # REPL
// ----------------------------------------------------------------------------

pub fn rep(src: String, l4u: L4uObj) -> Result(Expr, String) {
  //let exprs = read(src, l4u.get_env())
  //let result = eval(exprs, UNDEFINED, l4u.get_env())
  let result = l4u_read_eval(l4u, src)
  result
}

@target(javascript)
pub fn repl(l4u: L4uObj, prompt: String) {
  console_readline(prompt)
  |> promise.await(promise.resolve)
  |> promise.tap(fn(line) {
    let result =
      catch_ex(fn() {
        process_dict_set(env.pdic, "*trace_ip", 0)
        let assert WithEnv(result, new_env) = rep(line, env)

        repl_print(result)
        new_env
      })

    repl_loop(env, result, prompt)
  })
}

@target(erlang)
pub fn repl(l4u: L4uObj, prompt: String) {
  gdb__ && trace_set_last_funcall(UNDEFINED, l4u.get_env())
  //let line = console_readline(prompt)

  let str_prompt =
    {
      stringify(l4u.pid)
      |> string.replace("<", "|")
      |> string.replace(">", "|")
    } <> "" <> l4u.name <> "|" <> prompt
  //let str_prompt = "user> "

  let line = console_readline(str_prompt)
  case string.length(string.trim(line)) {
    0 -> {
      console_writeln("")
      repl(l4u, prompt)
    }
    _ -> {
      let result =
        catch_ex(fn() {
          process_dict_set(l4u.get_env().pdic, "*trace_ip", 0)
          let result = rep(line, l4u)
          case result {
            Ok(res) -> {
              res
            }
            Error(err) -> {
              io.println("Error: " <> error_to_string(err, False))
              PRINTABLE(STRING(""))
            }
          }
        })

      repl_loop(l4u, result, prompt)
    }
  }
}

fn repl_loop(l4u: L4uObj, result: Result(Expr, Expr), prompt: String) {
  // DEBUG
  //bif_inspect_env([], env)

  //dbgout2("repl_loop: result:", result)

  case result {
    Ok(retval) -> {
      case retval {
        ReplCommand("repl-switch", NativeValue("l4u", new_l4u)) -> {
          repl(unsafe_corece(new_l4u), prompt)
        }
        _ -> {
          repl_print(retval)
          repl(l4u, prompt)
        }
      }
    }

    Error(err) -> {
      let print_error = fn(env) {
        console_writeln("Error: " <> error_to_string(err, False))
        case l4u.get_env().opts.verbose {
          True -> {
            dump_env("repl", l4u.get_env())
            dbgout2(
              "last funcall:",
              process_dict_get(l4u.get_env().pdic, "last_funcall"),
            )
            dbgout2(
              "last expr:",
              process_dict_get(l4u.get_env().pdic, "last_expr"),
            )
          }
          False -> {
            False
          }
        }
      }
      exec_native(l4u.pid, print_error)
      repl(l4u, prompt)
    }
  }
}

// ----------------------------------------------------------------------------
// # main
// ----------------------------------------------------------------------------

pub fn main_l4u() -> L4uObj {
  global.get("*main-l4u*")
  |> unsafe_corece
}

pub fn start_and_generate_main_l4u(
  additional_defs: List(#(String, Expr)),
) -> L4uObj {
  gleam_bridge.init()

  let #(l4u, _) = generate_l4u_process("main", additional_defs)
  global.put("*main-l4u*", dynamic.from(l4u))

  l4u
}

pub fn main() {
  start_with_defs([])
}

pub fn start_with_defs(defs: List(#(String, Expr))) {
  let l4u = start_and_generate_main_l4u([])

  //
  //l4u_add_defs(l4u, defs)

  repl(l4u, "l4u> ")
}
