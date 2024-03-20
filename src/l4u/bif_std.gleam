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
  do_async, escape_binary_string, internal_form, l4u_to_native, load_file,
  make_ref, native_to_l4u, os_cmd, process_dict_get, process_dict_keys,
  process_dict_set, reset_ref, throw_err, throw_expr, unescape_binary_string,
  unique_int,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, rep, repl, show,
  to_l4u_bool, tokenize, trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{
  type Env, type Expr, BIF, BISPFORM, FALSE, FLOAT, INT, LIST, STRING, TRUE,
  UNDEFINED, WithEnv, native_false, native_nil, native_true, native_undefined,
  to_native_dictionary, unbox_l4u, unsafe_corece,
}
import l4u/l4u_core as l4u

// ----------------------------------------------------------------------------
// # library
// ----------------------------------------------------------------------------

// (unique-int)
fn bif_unique_int(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(INT(unique_int()), env)
}

// ---------------------------------------------------------------------------
// # convert
// ---------------------------------------------------------------------------

// (int Expr)
fn bif_int(exprs: List(Expr), env: Env) -> Expr {
  let rexpr = case exprs {
    [INT(val) as expr] -> expr
    [FLOAT(val)] -> INT(float.truncate(val))
    [x] ->
      INT(
        int.parse(pstr(x))
        |> result.unwrap(0),
      )
    unhandable -> {
      throw_expr(unhandable)
      INT(0)
    }
  }
  WithEnv(rexpr, env)
}

// (float Expr)
fn bif_float(exprs: List(Expr), env: Env) -> Expr {
  let rexpr = case exprs {
    [FLOAT(val) as expr] -> expr
    [INT(val)] -> FLOAT(int.to_float(val))
    [x] ->
      FLOAT(
        float.parse(pstr(x))
        |> result.unwrap(0.0),
      )
    unhandable -> {
      throw_expr(unhandable)
      FLOAT(0.0)
    }
  }
  WithEnv(rexpr, env)
}

// (string Expr Delimiter)
fn bif_string(exprs: List(Expr), env: Env) -> Expr {
  let #(vals, delimiter) = case exprs {
    [vals] -> #(uneval(vals), "")
    [vals, delimiter] -> #(uneval(vals), pstr(delimiter))
    unhandable -> {
      throw_expr(unhandable)
      #(STRING(""), "")
    }
  }
  case vals {
    LIST(vals) -> {
      let str =
        list.map(exprs, fn(expr) { pstr(expr) })
        |> string.join("")
      WithEnv(STRING(str), env)
    }
    x -> WithEnv(STRING(pstr(x)), env)
  }
}

// ---------------------------------------------------------------------------
// #
// ---------------------------------------------------------------------------

// (assert Expr)
fn bif_assert(exprs: List(Expr), env: Env) -> Expr {
  let assert WithEnv(eexpr, renv) = eval(exprs, UNDEFINED, env)
  case eexpr {
    TRUE -> TRUE
    _ -> {
      throw_expr(exprs)
      FALSE
    }
  }
  WithEnv(TRUE, env)
}

// (tokenize Expr)
fn bif_tokenize(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(val)] = exprs

  let rexpr = list.map(tokenize(val, env), fn(x) { STRING(x) })

  WithEnv(LIST(rexpr), env)
}

@external(erlang, "l4u@bif_std_ffi", "json_format")
@external(javascript, "../l4u_bif_std_ffi.mjs", "json_format")
fn json_format(expr: Expr) -> String

@target(javascript)
@external(javascript, "../l4u_bif_std_ffi.mjs", "native_to_json")
fn native_to_json(x: any) -> String

// (json-format Expr) -> STRING
fn bif_json_format(exprs: List(Expr), env: Env) -> Expr {
  let assert [rexpr] = exprs
  //dbgout2("bif_json_format", rexpr)
  //let rexpr = uneval(expr)
  WithEnv(STRING(json_format(rexpr)), env)
}

@external(erlang, "l4u@bif_std_ffi", "json_parse")
@external(javascript, "../l4u_bif_std_ffi.mjs", "json_parse")
fn json_parse(val: String) -> Expr

// (json-parse STRING) -> Expr
fn bif_json_parse(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(val)] = exprs
  let rexpr = json_parse(val)
  WithEnv(rexpr, env)
}

// (escape STRING) -> STRING
fn bif_escape(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(val)] = exprs
  let rexpr = escape_binary_string(val)
  WithEnv(STRING(rexpr), env)
}

// (unescape STRING) -> STRING
fn bif_unescape(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(val)] = exprs
  let rexpr = unescape_binary_string(val)
  WithEnv(STRING(rexpr), env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_std_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    //bif("pr-str", bif_pr_str),
    bif("unique-int", bif_unique_int),
    // convert
    bif("int", bif_int),
    bif("float", bif_float),
    bif("string", bif_string),
    //
    bsf("assert", bif_assert),
    bif("tokenize", bif_tokenize),
    bif("json-format", bif_json_format),
    bif("json-parse", bif_json_parse),
    bif("escape", bif_escape),
    bif("unescape", bif_unescape),
  ]
}
