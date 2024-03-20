////let assert [Scope(tvars), ..] = closure_env.scopes

// latest
import gleam/io
import gleam/list
import gleam/dict.{type Dict}
import gleam/string
import gleam/regex
import gleam/result
import gleam/int
import gleam/float
import gleam/dynamic
import gleam/option
import gleam/order.{type Order, Eq, Gt, Lt}
import l4u/sys_bridge.{
  aux_pdic, catch_ex, compare_any, console_readline, console_writeln, dbgout1,
  dbgout2, dbgout3, deref, do_async, erl_sym, error_to_string,
  escape_binary_string, external_form, internal_form, load_file, make_ref,
  process_dict_erase, process_dict_get, process_dict_keys, process_dict_set,
  reset_ref, tco_loop, throw_err, throw_expr, tick_count, to_string,
  unescape_binary_string, unique_int, unique_pdic, unique_str,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_util
import l4u/l4u_type.{
  type Env, type Expr, type Info, type PDic, type Scope, ATOM, BIF, BISPFORM,
  CLOSURE, Continuation, CustomType, CustomTypeDef, DELIMITER, DICT, Description,
  Env, EnvOptions, ExVAR, FALSE, FLOAT, INT, Info, KEYWORD, LIST,
  LocalContinuation, MACRO, NIL, NativeFunction, PRINTABLE, ProcessDict, STRING,
  SYMBOL, Scope, TRUE, UNDEFINED, VECTOR, WithEnv, WithMeta, native_false,
  native_nil, native_true, native_undefined, to_native_dictionary, unsafe_corece,
}
import gleam_bridge
import l4u/union_term

const gdb__ = True

const gverbose__ = False

const gv_parse__ = False

const binop__ = False

const tco__ = True

const bif_to_global_scope__ = True

type ScopeType {
  ScopeTypeOverwriteLocal
  ScopeTypeSimpleScopes
  ScopeTypeOptScopes
}

const scope_type__ = ScopeTypeOverwriteLocal

//const scope_type__ = ScopeTypeSimpleScopes
//const scope_type__ = ScopeTypeOptScopes

pub fn to_l4u_bool(flag: Bool) -> Expr {
  case flag {
    True -> TRUE
    False -> FALSE
  }
}

pub fn is_true_condition(e: Expr) -> Bool {
  case e {
    // 0はtrue扱い。| INT(0) 
    // | LIST([])
    //FALSE | NIL | UNDEFINED | LIST([]) | VECTOR([]) | DICT([]) | STRING("") ->
    FALSE | NIL | UNDEFINED -> False
    _ -> True
  }
}

pub fn is_empty_value(val: Expr) {
  case val {
    //LIST([]) | VECTOR([]) | DICT([]) -> True
    //UNDEFINED | NIL | LIST([]) | VECTOR([]) | DICT([]) -> True
    UNDEFINED | NIL | LIST([]) | VECTOR([]) | DICT([]) | STRING("") -> True
    _ -> False
  }
}

pub fn is_nil_value(val: Expr) {
  case val {
    NIL -> True
    _ -> False
  }
}

pub fn is_true_value(val: Expr) {
  case val {
    TRUE -> True
    _ -> False
  }
}

pub fn is_false_value(val: Expr) {
  case val {
    FALSE -> True
    _ -> False
  }
}

@target(javascript)
pub const host_language = STRING("gleam-javascript")

@target(erlang)
pub const host_language = STRING("gleam-erlang")

pub const sym_quote = SYMBOL("quote")

//pub const sym_quasiquote = SYMBOL("quasiquote")

//pub const sym_quasiquote = SYMBOL("quasiquoteexpand-X")

//pub const sym_quasiquote = SYMBOL("quasiquoteexpand")

pub const sym_quasiquote = SYMBOL("quasiquote")

pub const sym_unquote = SYMBOL("unquote")

//pub const sym_unquote_splicing = SYMBOL("unquote-splicing")

pub const sym_unquote_splicing = SYMBOL("splice-unquote")

pub const sym_list = SYMBOL("list")

pub fn description(name: String) {
  Description(name, "")
}

pub fn description_with_text(name: String, text: String) {
  Description(name, text)
}

// ----------------------------------------------------------------------------
// # read
// ----------------------------------------------------------------------------

const pattern = "[\\s]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)"

fn skip_line_comment(source: String) -> String {
  case string.pop_grapheme(source) {
    Ok(#("", rest)) -> rest
    Ok(#("\n", rest)) -> rest
    Ok(#(_, rest)) -> skip_line_comment(rest)
    Error(_) -> ""
  }
}

fn skip_block_comment(source: String) -> String {
  case source {
    "*/" <> rest -> rest
    _ -> {
      case string.pop_grapheme(source) {
        Ok(#(_, rest)) -> skip_block_comment(rest)
        Error(_) -> ""
      }
    }
  }
}

fn remove_comment_from_source(source: String, trimmed: String) {
  case source {
    // remove shebang
    "#!/" <> rest ->
      remove_comment_from_source(skip_line_comment(rest), trimmed)

    // line comment
    ";" <> rest -> remove_comment_from_source(skip_line_comment(rest), trimmed)

    // block comment
    "/*" <> rest ->
      remove_comment_from_source(skip_block_comment(rest), trimmed)
    "" -> trimmed
    _ -> {
      case string.pop_grapheme(source) {
        Ok(#(char, rest)) -> remove_comment_from_source(rest, trimmed <> char)
        _ -> trimmed
      }
    }
  }
}

fn remove_comment(source: String) {
  case source {
    // remove shebang
    "#!/" <> rest -> ""

    // line comment
    ";" <> rest -> ""

    "" -> ""
    _ -> {
      source
    }
  }
}

pub fn string_trim(source: String) -> String {
  let #(char, rest) =
    string.pop_grapheme(source)
    |> result.unwrap(#("", ""))
  case char {
    "" -> ""
    " " | "\r" | "\n" | "\t" -> string_trim(rest)
    _ -> source
  }
}

pub fn tokenize(src: String, env: Env) -> List(String) {
  // これはだめ。文字列の中の;もコメント扱いしてしまう
  //let src = string_trim(remove_comment(src, ""))
  let lines =
    l4u_util.split_multiline_string(src)
    |> list.map(fn(line) {
      case line {
        "\"\"\"" <> _ -> [line]
        _ -> tokenize_1(line, env)
      }
    })
    |> list.flatten

  //dbgout2("# lines:", lines)

  lines
}

fn tokenize_1(src: String, env: Env) -> List(String) {
  //dbgout1("tokenize:" <> src)
  //dbgout2("regex:", env.regex)
  let tokens =
    regex.split(process_dict_get(env.pdic, "*regex"), src)
    |> list.map(fn(str) {
      str
      |> string.trim
      |> remove_comment()
    })
    |> list.filter(fn(x) { x != "" })
}

pub fn read(src: String, env: Env) -> List(Expr) {
  let tokens = tokenize(src, env)

  //list.each(tokens, dbgout1)

  let exprs = read_(tokens, [], env)
  //list.each(exprs, fn(x) { dbgout1(inspect(x)) })
  exprs
}

fn read_(tokens: List(String), acc: List(Expr), env: Env) -> List(Expr) {
  case tokens {
    [] -> list.reverse(acc)
    _ -> {
      let #(expr, rest) = parse(tokens, env)
      read_(rest, [expr, ..acc], env)
    }
  }
}

// ----------------------------------------------------------------------------
// # macro
// ----------------------------------------------------------------------------

pub fn apply_macro(expr: Expr, env: Env) -> Expr {
  let old = expr
  let new = apply_macro_(expr, env)
  case old == new {
    True -> {
      //dbgout2("expanded macro:", new)
      new
    }
    _ -> apply_macro(new, env)
  }
}

fn apply_macro_(expr: Expr, env: Env) -> Expr {
  case expr {
    LIST([SYMBOL(callable), ..args] as exprs) -> {
      case env_get(env, callable) {
        Ok(MACRO(..) as macroval) -> {
          let assert WithEnv(new_expr, new_env) = apply(env, macroval, args)
          new_expr
        }

        _ -> {
          LIST(list.map(exprs, fn(e) { apply_macro_(e, env) }))
        }
      }
    }

    x -> x
  }
}

fn apply_macro_1(expr: Expr, env: Env) -> Expr {
  case expr {
    LIST([SYMBOL(callable), ..args] as exprs) -> {
      case env_get(env, callable) {
        Ok(MACRO(..) as macroval) -> {
          let assert WithEnv(new_expr, new_env) = apply(env, macroval, args)
          new_expr
        }

        _ -> {
          //LIST(list.map(exprs, fn(e) { apply_macro_(e, env) }))
          expr
        }
      }
    }

    x -> x
  }
}

// ----------------------------------------------------------------------------
// # parse
// ----------------------------------------------------------------------------

pub fn intern_symbol(str: String) -> Expr {
  case str {
    "undefined" -> UNDEFINED
    "nil" -> NIL
    "true" -> TRUE
    "false" -> FALSE
    //_ -> SYMBOL(str)
    _ -> {
      let new_key = erl_sym(str)
      case union_term.nt_get_with_default(new_key, UNDEFINED) {
        UNDEFINED -> {
          let new_symbol = SYMBOL(str)
          union_term.nt_put(new_key, new_symbol)
          new_symbol
        }
        interened_symbol -> interened_symbol
      }
    }
  }
}

pub fn intern_keyword(str: String) -> Expr {
  //KEYWORD(string.uppercase(str))
  case string.starts_with(str, ":") {
    True -> KEYWORD(string.drop_left(from: str, up_to: 1))
    _ -> KEYWORD(str)
  }
}

pub fn intern_symbol_or_keyword(str: String) -> Expr {
  //case string.starts_with(str, ":") {
  //  True -> intern_keyword(str)
  //  False -> intern_symbol(str)
  //}

  case string.pop_grapheme(str) {
    Ok(#(":", rest)) -> intern_keyword(rest)
    Ok(#("$", rest)) -> {
      ExVAR("external", rest)
    }
    _ -> intern_symbol(str)
  }
}

fn parse_list_delimiter(
  tokens: List(String),
  acc: List(Expr),
  terminator: String,
  env: Env,
) -> #(List(Expr), List(String)) {
  case tokens {
    [",", ..rest] -> parse_list(rest, acc, terminator, env)
    _ -> parse_list(tokens, acc, terminator, env)
  }
}

pub fn parse_list(
  tokens: List(String),
  acc: List(Expr),
  terminator: String,
  env: Env,
) -> #(List(Expr), List(String)) {
  case tokens {
    [token, ..rest] if token == terminator -> #(list.reverse(acc), rest)
    _ -> {
      let #(expr, rest) = parse(tokens, env)
      parse_list_delimiter(rest, [expr, ..acc], terminator, env)
    }
  }
}

pub fn parse_string(str: String, env: Env) -> Expr {
  let assert Ok(True) = Ok(string.ends_with(str, "\""))
  STRING(unescape_binary_string(string.slice(str, 0, string.length(str) - 1)))
}

pub fn parse_string_block(str: String, env: Env) -> Expr {
  //dbgout2("parse_string_block:", str)
  let assert Ok(True) = Ok(string.ends_with(str, "\"\"\""))
  STRING(string.slice(str, 0, string.length(str) - 3))
}

pub fn parse(tokens: List(String), env: Env) -> #(Expr, List(String)) {
  let #(expr, rest) = parse_(tokens, env)

  case env.opts.verbose {
    True -> {
      case expr {
        LIST(..) -> {
          gv_parse__ && dbgout2("parse:", expr)
          Nil
        }
        _ -> {
          gv_parse__ && dbgout2("parse:", expr)
          Nil
        }
      }
    }
    _ -> Nil
  }
  let expr2 = apply_macro(expr, env)
  #(expr2, rest)
}

fn parse_(tokens: List(String), env: Env) -> #(Expr, List(String)) {
  case tokens {
    ["@", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      #(LIST([SYMBOL("deref"), expr]), rest2)
    }
    ["^", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      let #(expr2, rest3) = parse(rest2, env)
      #(LIST([SYMBOL("with-meta"), expr2, expr]), rest3)
    }
    ["'", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      #(LIST([sym_quote, expr]), rest2)
    }
    ["`", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      #(LIST([sym_quasiquote, expr]), rest2)
    }
    ["~", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      #(LIST([sym_unquote, expr]), rest2)
    }
    ["~@", ..rest_token] -> {
      let #(expr, rest2) = parse(rest_token, env)
      #(LIST([sym_unquote_splicing, expr]), rest2)
    }
    ["(", ..rest_tokens] -> {
      let #(exprs, rest2) = parse_list(rest_tokens, [], ")", env)
      #(LIST(exprs), rest2)
    }
    ["[", ..rest_tokens] -> {
      let #(exprs, rest2) = parse_list(rest_tokens, [], "]", env)
      #(VECTOR(exprs), rest2)
    }
    ["{", ..rest_tokens] -> {
      let #(exprs, rest2) = parse_list(rest_tokens, [], "}", env)
      #(DICT(exprs), rest2)
    }
    [token, ..rest_tokens] -> {
      #(parse_expr(token, env), rest_tokens)
    }
    _ -> {
      dbgout2("invalid token:", tokens)
      throw_err("invalid token")
      #(UNDEFINED, [])
    }
  }
}

pub fn parse_expr(token: String, env: Env) -> Expr {
  case token {
    "\"\"\"" <> str -> {
      parse_string_block(str, env)
    }
    "\"" <> str -> {
      parse_string(str, env)
    }
    _ -> {
      case int.parse(token) {
        Ok(value) -> INT(value)
        Error(_) -> {
          case float.parse(token) {
            Ok(value) -> FLOAT(value)
            Error(_) -> intern_symbol_or_keyword(token)
          }
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// # eval
// ----------------------------------------------------------------------------

@target(javascript)
pub fn eval(exprs: List(Expr), result: Expr, env: Env) -> Expr {
  let f_tco = fn(fn_params) {
    //let assert #(exprs: List(Expr), result: Expr, env: Env) = fn_params
    let assert #(exprs, result, env) = fn_params
    case exprs {
      [] -> Ok(WithEnv(result, env))

      [WithEnv(result, new_env) as ret] -> {
        Ok(ret)
      }

      [Continuation(progn, new_env) as ret] -> {
        Error(#(progn, UNDEFINED, new_env))
      }

      [LocalContinuation(progn, new_env, next_env) as ret] -> {
        Error(#(progn, UNDEFINED, new_env))
      }

      // tail call optimization(TCO)
      [expr] -> {
        //io.println("- TCO: " <> print(expr))
        //Error(#([expr], UNDEFINED, env))
        Error(#([eval_expr(expr, env)], UNDEFINED, env))
      }
      [expr, ..rest] -> {
        //io.println("- " <> print(expr))
        let assert WithEnv(rexpr, renv) = eval([expr], UNDEFINED, env)
        Error(#(rest, rexpr, renv))
      }
    }
  }
  tco_loop(f_tco, #(exprs, result, env))
}

@target(erlang)
pub fn eval(exprs: List(Expr), result: Expr, env: Env) -> Expr {
  case exprs {
    [] -> WithEnv(result, env)

    [WithEnv(result, new_env) as ret] -> {
      ret
    }

    [Continuation(progn, new_env) as ret] -> {
      eval(progn, UNDEFINED, new_env)
    }

    // tail call optimization(TCO)
    [expr] -> {
      //io.println("- TCO: " <> print(expr))
      let ret = eval_expr(expr, env)
      eval([ret], UNDEFINED, env)
    }
    //eval([eval_expr(expr, env)], UNDEFINED, env)
    [expr, ..rest] -> {
      //let assert WithEnv(rexpr, renv) = eval_expr(expr, env)
      //eval([eval_expr(expr, env)], UNDEFINED, env)
      let assert WithEnv(rexpr, renv) = eval([expr], UNDEFINED, env)
      eval(rest, rexpr, renv)
    }
  }
}

pub fn eval_contents(
  exprs: List(Expr),
  acc: List(Expr),
  env: Env,
) -> #(List(Expr), Env) {
  case exprs {
    [] -> #(list.reverse(acc), env)
    [expr, ..rest] -> {
      let assert WithEnv(result, new_env) = eval([expr], UNDEFINED, env)
      //let assert WithEnv(result, new_env) = eval_expr(expr, env)
      eval_contents(rest, [result, ..acc], new_env)
    }
  }
}

pub fn eval_funcall_args(exprs: List(Expr), env: Env) -> #(List(Expr), Env) {
  let #(eargs, new_env) = eval_contents(exprs, [], env)
  //
  //  let eargs = case binop__ {
  //    True -> {
  //      case eargs {
  //        [BIF(..), _, _] -> eargs
  //        [CLOSURE(..), _, _] -> eargs
  //        [BISPFORM(..), _, _] -> eargs
  //        [MACRO(..), _, _] -> eargs
  //        [e1, e2, e3] -> {
  //          [e2, e1, e3]
  //        }
  //        _ -> eargs
  //      }
  //    }
  //    _ -> eargs
  //  }
  //  #(eargs, new_env)
}

fn bind_args(
  bindings: Dict(String, Expr),
  params: List(String),
  args: List(Expr),
) -> Dict(String, Expr) {
  //dbgout3("bind_args:", params, args)
  case params, args {
    [], [] -> bindings
    ["&", sym_rest], rest_args -> {
      dict.insert(bindings, sym_rest, LIST(rest_args))
    }
    //[param], [] -> {
    //  io.println("[param],[]")
    //  //dict.insert(bindings, param, NIL)
    //  dict.insert(bindings, param, LIST([]))
    //}
    [param, ..rest_params], [arg, ..rest_args] -> {
      bind_args(dict.insert(bindings, param, arg), rest_params, rest_args)
    }
    _, _ -> {
      throw_err("unhandable args")
      bindings
    }
  }
}

pub fn unwrap(expr: Expr) -> Expr {
  case expr {
    WithMeta(e, _meta) -> {
      e
    }
    _ -> expr
  }
}

pub fn uneval(expr: Expr) -> Expr {
  case expr {
    VECTOR(contents) -> LIST(contents)
    LIST(contents) -> LIST(contents)
    DICT(contents) -> LIST(contents)
    _ -> expr
  }
}

pub fn eval_expr(expr: Expr, env: Env) -> Expr {
  case expr {
    LIST([SYMBOL("meta"), WithMeta(_, meta)]) -> {
      WithEnv(meta, env)
    }
    _ -> eval_expr_(unwrap(expr), env)
  }
}

fn generate_local_env__overwrite_local(
  name: String,
  env: Env,
  bindings: Dict(String, Expr),
  a_bindings: Dict(String, Expr),
) -> Env {
  Env(
    ..env,
    info: Info(name, env.info.level + 1),
    local_vars: dict.merge(env.local_vars, bindings),
    a_binding: dict.merge(env.a_binding, a_bindings),
  )
}

fn generate_local_env__opt_scopes(
  name: String,
  env: Env,
  bindings: Dict(String, Expr),
  a_bindings: Dict(String, Expr),
) -> Env {
  case dict.size(bindings) {
    0 -> env
    _ -> {
      Env(
        ..env,
        info: Info(name, env.info.level + 1),
        local_vars: bindings,
        a_binding: dict.merge(env.a_binding, a_bindings),
        scopes: [Scope(env.local_vars), ..env.scopes],
      )
    }
  }
}

fn generate_local_env__simple_scope(
  name: String,
  env: Env,
  bindings: Dict(String, Expr),
  a_bindings: Dict(String, Expr),
) -> Env {
  Env(
    ..env,
    info: Info(name, env.info.level + 1),
    local_vars: bindings,
    a_binding: dict.merge(env.a_binding, a_bindings),
    scopes: [Scope(env.local_vars), ..env.scopes],
  )
}

fn generate_local_env(
  name: String,
  env: Env,
  bindings: Dict(String, Expr),
  a_bindings: Dict(String, Expr),
) -> Env {
  case scope_type__ {
    ScopeTypeOverwriteLocal -> {
      generate_local_env__overwrite_local(name, env, bindings, a_bindings)
    }
    ScopeTypeSimpleScopes -> {
      generate_local_env__simple_scope(name, env, bindings, a_bindings)
    }
    ScopeTypeOptScopes -> {
      generate_local_env__opt_scopes(name, env, bindings, a_bindings)
    }
  }
}

@external(erlang, "l4u@bif_lib", "invoke_native_function")
@external(javascript, "../l4u_bif_lib_ffi.mjs", "invoke_native_function")
fn invoke_native_function(nt_fun: Expr, args: List(Expr)) -> Expr

// LIST(fn,arg1,arg2,...): 関数実行
// SYMBOL: 変数参照
fn eval_expr_(expr: Expr, env: Env) -> Expr {
  let result = case expr {
    LIST([callable, ..args]) -> {
      gdb__ && env.opts.trace && trace_set_last_funcall(expr, env)

      //let assert WithEnv(ecallable, new_env) = eval([callable], UNDEFINED, env)
      let assert WithEnv(ecallable, new_env) = case callable {
        LIST(..) -> eval([callable], UNDEFINED, env)
        _ -> eval_expr_(callable, env)
      }

      case unwrap(ecallable) {
        // call special form
        BISPFORM(_, f) -> f(args, new_env)

        // call bif
        BIF(_, f) -> {
          let #(eargs, new_env) = eval_funcall_args(args, new_env)

          f(eargs, new_env)
        }

        NativeFunction(_name, _nt_fun) as nt_fun -> {
          let #(eargs, new_env) = eval_funcall_args(args, new_env)
          let rexpr = invoke_native_function(unsafe_corece(nt_fun), eargs)
          WithEnv(rexpr, new_env)
        }

        // call closure
        CLOSURE(_, params, progn, closure_env) as closure -> {
          //gdb__ && env.opts.trace && dump_closure("call closure", closure)

          //io.println("1:" <> dump_local_vars(closure_env))
          // closureに渡す引数を評価する
          let #(eargs, new_env) = eval_funcall_args(args, new_env)

          // closureの引数を束縛する
          let bindings = bind_args(dict.from_list([]), params, eargs)
          //let bindings = bind_args(closure_env.local_vars, params, eargs)
          let ip =
            trace_closure_call(closure_env, callable, ecallable, bindings)

          let new_closure_env =
            generate_local_env(
              "call closure",
              closure_env,
              bindings,
              env.a_binding,
            )
          //  Env(
          //    ..closure_env,
          //    local_vars: bindings,
          //    scopes: [Scope(closure_env.local_vars), ..closure_env.scopes],
          //  )

          //io.println("2:" <> dump_local_vars(new_closure_env))
          let assert WithEnv(rexpr, _) as return =
            local_continuation(progn, new_closure_env, new_env)
          trace_closure_return(closure_env, callable, ecallable, rexpr, ip)
          return
        }
        // call macro
        MACRO(info, params, progn, macro_env) -> {
          let bindings = dict.from_list([])
          //let #(eargs, new_env) = eval_contents(args, [], new_env)
          let bindings = bind_args(bindings, params, args)

          let new_local_env =
            Env(..macro_env, scopes: [Scope(bindings: bindings), ..env.scopes])

          //bif_progn(progn, new_env)
          local_continuation(progn, new_local_env, env)
        }

        // first argument is not function
        _ -> WithEnv(UNDEFINED, env)
      }
    }

    VECTOR(contents) -> {
      let #(eargs, new_env) = eval_contents(contents, [], env)
      //WithEnv(LIST(eargs), new_env)
      WithEnv(VECTOR(eargs), new_env)
    }
    DICT(contents) -> {
      let #(eargs, new_env) = eval_contents(contents, [], env)
      //WithEnv(LIST(eargs), new_env)
      WithEnv(DICT(eargs), new_env)
    }
    SYMBOL(sym) -> {
      gdb__ && env.opts.trace && trace_set_last_expr(expr, env)
      //dump_dict(env.bindings, env)
      case env_get(env, sym) {
        Ok(value) -> {
          WithEnv(value, env)
        }
        _ -> {
          throw_err("'" <> sym <> "' not found")
          WithEnv(UNDEFINED, env)
        }
      }
    }
    ExVAR(etype, esym) -> {
      case union_term.get_with_default(etype, UNDEFINED) {
        UNDEFINED -> {
          throw_err("'" <> etype <> "' not found")
          WithEnv(UNDEFINED, env)
        }
        CLOSURE(..) as f -> {
          let expr = LIST([f, STRING(esym)])
          //dbgout2("ExVAR:", expr)
          eval_expr(expr, env)
        }
        unhandable -> {
          throw_err("unhandable exp in eval_expr")
          WithEnv(UNDEFINED, env)
        }
      }
    }
    _ -> {
      gdb__ && env.opts.trace && trace_set_last_expr(expr, env)
      WithEnv(expr, env)
    }
  }
}

fn local_continuation(exprs: List(Expr), local_env: Env, eval_env: Env) -> Expr {
  //*NG* let assert WithEnv(rexpr, r_env) = eval(exprs, UNDEFINED, eval_env)
  //*NG* WithEnv(rexpr, r_env)
  //*NG* WithEnv(rexpr, local_env)
  //LocalContinuation(exprs, local_env, eval_env)

  let assert WithEnv(rexpr, r_env) = eval(exprs, UNDEFINED, local_env)
  WithEnv(rexpr, eval_env)
}

fn continuation(exprs: List(Expr), local_env: Env) -> Expr {
  case tco__ {
    True -> {
      Continuation(exprs, local_env)
    }
    _ -> {
      eval(exprs, UNDEFINED, local_env)
    }
  }
}

// ----------------------------------------------------------------------------
// # printer
// ----------------------------------------------------------------------------

// print implementation
pub fn print(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> print(expr)
    UNDEFINED -> "undefined"
    NIL -> "nil"
    TRUE -> "true"
    FALSE -> "false"
    FLOAT(val) -> float.to_string(val)
    INT(val) -> int.to_string(val)
    STRING(val) -> {
      "\"" <> escape_binary_string(val) <> "\""
    }
    SYMBOL(val) -> val
    KEYWORD(val) -> ":" <> val
    DELIMITER -> ""
    LIST(val) -> {
      "(" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> ")"
    }
    VECTOR(val) -> {
      "[" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "]"
    }
    DICT(val) -> {
      "{" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "}"
    }
    CLOSURE(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      "(fn* ("
      <> string.join(params, " ")
      <> ") "
      <> string.join(body, " ")
      <> ")"
    }
    ATOM(ref) -> "(atom " <> print(deref(ref)) <> ")"
    BIF(desc, ..) -> desc.name
    BISPFORM(desc, ..) -> "#<bispform:" <> desc.name <> ">"
    WithMeta(expr, meta) -> print(expr)
    MACRO(..) -> "#<macro>"
    CustomTypeDef(name, expr) ->
      "(custom-type-def " <> name <> " " <> print(expr) <> ">"
    CustomType(name, expr) -> "(" <> name <> " " <> print(expr) <> " )"
    _ -> external_form(expr)
  }
}

pub fn pstr(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> pstr(expr)
    UNDEFINED -> "undefined"
    NIL -> "nil"
    TRUE -> "true"
    FALSE -> "false"
    FLOAT(val) -> float.to_string(val)
    INT(val) -> int.to_string(val)
    STRING(val) -> val
    SYMBOL(val) -> val
    KEYWORD(val) -> val
    DELIMITER -> ""
    LIST(val) -> {
      string.join(list.map(val, fn(expr) { pstr(expr) }), " ")
    }
    VECTOR(val) -> {
      string.join(list.map(val, fn(expr) { pstr(expr) }), " ")
    }
    DICT(val) -> {
      string.join(list.map(val, fn(expr) { pstr(expr) }), " ")
    }
    CLOSURE(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      "(fn* ("
      <> string.join(params, " ")
      <> ") "
      <> string.join(body, " ")
      <> ")"
    }
    ATOM(..) -> "#<atom>"
    BIF(desc, ..) -> desc.name
    BISPFORM(desc, ..) -> "#<bispform:" <> desc.name <> ">"
    WithMeta(expr, meta) -> pstr(expr)
    MACRO(..) -> "#<macro>"
    CustomTypeDef(name, expr) ->
      "(custom-type-def " <> name <> " " <> print(expr) <> ">"
    CustomType(name, expr) -> "(" <> name <> " " <> print(expr) <> " )"
    _ -> external_form(expr)
  }
}

pub fn show(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> show(expr)
    UNDEFINED -> "undefined"
    NIL -> "nil"
    TRUE -> "true"
    FALSE -> "false"
    FLOAT(val) -> float.to_string(val)
    INT(val) -> int.to_string(val)
    STRING(val) -> val
    SYMBOL(val) -> val
    KEYWORD(val) -> ":" <> val
    DELIMITER -> ""
    LIST(val) -> {
      "(" <> string.join(list.map(val, fn(expr) { show(expr) }), " ") <> ")"
    }
    VECTOR(val) -> {
      "[" <> string.join(list.map(val, fn(expr) { show(expr) }), " ") <> "]"
    }
    DICT(val) -> {
      "{" <> string.join(list.map(val, fn(expr) { show(expr) }), " ") <> "}"
    }
    CLOSURE(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      "(fn* ("
      <> string.join(params, " ")
      <> ") "
      <> string.join(body, " ")
      <> ")"
    }
    ATOM(..) -> "#<atom>"
    BIF(desc, ..) -> desc.name
    BISPFORM(desc, ..) -> "#<bispform:" <> desc.name <> ">"
    WithMeta(expr, meta) -> show(expr)
    MACRO(..) -> "#<macro>"
    CustomTypeDef(name, expr) ->
      "(custom-type-def " <> name <> " " <> print(expr) <> ">"
    CustomType(name, expr) -> "(" <> name <> " " <> print(expr) <> " )"
    _ -> external_form(expr)
  }
}

pub fn print_2(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> print(expr)
    UNDEFINED -> "undefined"
    NIL -> "nil"
    TRUE -> "true"
    FALSE -> "false"
    FLOAT(val) -> float.to_string(val)
    INT(val) -> int.to_string(val)
    STRING(val) -> val
    SYMBOL(val) -> val
    KEYWORD(val) -> ":" <> val
    DELIMITER -> ""
    LIST(val) -> {
      "(" <> string.join(list.map(val, fn(expr) { print(expr) }), ", ") <> ")"
    }
    VECTOR(val) -> {
      "[" <> string.join(list.map(val, fn(expr) { print(expr) }), ", ") <> "]"
    }
    DICT(val) -> {
      "{" <> string.join(list.map(val, fn(expr) { print(expr) }), ", ") <> "}"
    }
    CLOSURE(..) -> "#<closure>"
    ATOM(..) -> "#<atom>"
    BIF(desc, ..) -> "#<bif:" <> desc.name <> ">"
    BISPFORM(desc, ..) -> "#<bispform:" <> desc.name <> ">"
    WithMeta(expr, meta) -> print(expr)
    MACRO(..) -> "#<macro>"
    CustomTypeDef(name, expr) ->
      "(custom-type-def " <> name <> " " <> print(expr) <> ">"
    CustomType(name, expr) -> "(" <> name <> " " <> print(expr) <> " )"
    _ -> internal_form(expr)
  }
}

pub fn inspect(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> print(expr)
    UNDEFINED -> "undefined"
    NIL -> "nil"
    TRUE -> "true"
    FALSE -> "false"
    FLOAT(val) -> "(FLOAT " <> float.to_string(val) <> ")"
    INT(val) -> "(INT " <> int.to_string(val) <> ")"
    STRING(val) -> "(STRING " <> val <> ")"
    SYMBOL(val) -> "(SYMBOL " <> val <> ")"
    KEYWORD(val) -> "(KEYWORD " <> val <> ")"
    DELIMITER -> ","
    LIST(val) -> {
      "(" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> ")"
    }
    VECTOR(val) -> {
      "[" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "]"
    }
    DICT(val) -> {
      "{" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "}"
    }
    CLOSURE(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      "(CLOSURE "
      <> desc.name
      <> " ("
      <> string.join(params, " ")
      <> ")\n  "
      <> string.join(body, " ")
      <> ")"
      <> "\n    "
      <> dump_local_vars(closure_env)
      <> "\n    "
      <> dump_scopes_keys(closure_env.scopes)
    }
    MACRO(info, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      "(MACRO ("
      <> string.join(params, " ")
      <> ") "
      <> string.join(body, " ")
      <> ")"
    }
    ATOM(ref) -> "#<atom>"
    BIF(desc, ..) -> "#<bif:" <> desc.name <> ">"
    BISPFORM(desc, ..) -> "#<bispform:" <> desc.name <> ">"
    WithMeta(expr, meta) ->
      "(with-meta " <> inspect(expr) <> " " <> inspect(meta) <> ")"
    CustomTypeDef(name, expr) ->
      "(custom-type-def " <> name <> " " <> print(expr) <> ">"
    CustomType(name, expr) -> "(" <> name <> " " <> print(expr) <> " )"
    _ -> internal_form(expr)
  }
}

pub fn describe(expr: Expr) -> String {
  case expr {
    WithEnv(expr, _) -> print(expr)
    UNDEFINED -> "(SPECIAL undefined)"
    NIL -> "(SPECIAL nil)"
    TRUE -> "(BOOL true)"
    FALSE -> "(BOOL false)"
    FLOAT(val) -> "(FLOAT " <> float.to_string(val) <> ")"
    INT(val) -> "(INT " <> int.to_string(val) <> ")"
    STRING(val) -> "(STRING " <> val <> ")"
    SYMBOL(val) -> "(SYMBOL " <> val <> ")"
    KEYWORD(val) -> "(KEYWORD " <> val <> ")"
    DELIMITER -> ","
    LIST(val) -> {
      "(" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> ")"
    }
    VECTOR(val) -> {
      "[" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "]"
    }
    DICT(val) -> {
      "{" <> string.join(list.map(val, fn(expr) { print(expr) }), " ") <> "}"
    }
    CLOSURE(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      desc.text
      <> "\n"
      <> "(CLOSURE "
      <> desc.name
      <> " ("
      <> string.join(params, " ")
      <> ")\n  "
      <> string.join(body, " ")
      <> ")"
    }
    MACRO(desc, params, body, closure_env) -> {
      let body = list.map(body, fn(e) { print(e) })
      desc.text
      <> "\n"
      <> "(MACRO  "
      <> desc.name
      <> " ("
      <> string.join(params, " ")
      <> ")\n  "
      <> string.join(body, " ")
      <> ")"
    }
    ATOM(ref) -> "#<atom>"
    BIF(desc, ..) -> "builtin function: " <> desc.name <> "\n" <> desc.text
    BISPFORM(desc, ..) -> "special form: " <> desc.name <> "\n" <> desc.text
    WithMeta(expr, meta) ->
      "(with-meta " <> inspect(expr) <> " " <> inspect(meta) <> ")"
    _ -> internal_form(expr)
  }
}

// ----------------------------------------------------------------------------
// # BIF(Built-in Function)
// ----------------------------------------------------------------------------

pub fn add2(x: Expr, y: Expr) -> Expr {
  case x, y {
    INT(x), INT(y) -> INT(x + y)
    FLOAT(x), FLOAT(y) -> FLOAT(x +. y)
    INT(x), FLOAT(y) -> FLOAT(int.to_float(x) +. y)
    FLOAT(x), INT(y) -> FLOAT(x +. int.to_float(y))
    _, _ -> UNDEFINED
  }
}

pub fn sub2(x: Expr, y: Expr) -> Expr {
  case x, y {
    INT(x), INT(y) -> INT(x - y)
    FLOAT(x), FLOAT(y) -> FLOAT(x -. y)
    INT(x), FLOAT(y) -> FLOAT(int.to_float(x) -. y)
    FLOAT(x), INT(y) -> FLOAT(x +. int.to_float(y))
    _, _ -> UNDEFINED
  }
}

pub fn mul2(x: Expr, y: Expr) -> Expr {
  case x, y {
    INT(x), INT(y) -> INT(x * y)
    FLOAT(x), FLOAT(y) -> FLOAT(x *. y)
    INT(x), FLOAT(y) -> FLOAT(int.to_float(x) *. y)
    FLOAT(x), INT(y) -> FLOAT(x *. int.to_float(y))
    _, _ -> UNDEFINED
  }
}

pub fn div2(x: Expr, y: Expr) -> Expr {
  case x, y {
    INT(x), INT(y) -> INT(x / y)
    FLOAT(x), FLOAT(y) -> FLOAT(x /. y)
    INT(x), FLOAT(y) -> FLOAT(int.to_float(x) /. y)
    FLOAT(x), INT(y) -> FLOAT(x /. int.to_float(y))
    _, _ -> UNDEFINED
  }
}

pub fn bif_add(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(list.fold(exprs, INT(0), add2), env)
}

pub fn bif_sub(exprs: List(Expr), env: Env) -> Expr {
  let assert [x, ..xs] = exprs
  WithEnv(list.fold(xs, x, sub2), env)
}

pub fn bif_mul(exprs: List(Expr), env: Env) -> Expr {
  let assert [x, ..xs] = exprs
  WithEnv(list.fold(xs, x, mul2), env)
}

pub fn bif_div(exprs: List(Expr), env: Env) -> Expr {
  let assert [x, ..xs] = exprs
  WithEnv(list.fold(xs, x, div2), env)
}

pub fn bif_mod(exprs: List(Expr), env: Env) -> Expr {
  let assert [INT(x), INT(y)] = exprs
  WithEnv(INT(x % y), env)
}

pub fn is_equal(first: Expr, second: Expr) -> Bool {
  case first, second {
    INT(x), INT(y) -> x == y
    FLOAT(x), FLOAT(y) -> x == y
    STRING(x), STRING(y) -> x == y
    SYMBOL(x), SYMBOL(y) -> x == y
    KEYWORD(x), KEYWORD(y) -> x == y
    LIST(x), LIST(y) -> compare(first, second) == Eq
    VECTOR(x), VECTOR(y) -> compare(first, second) == Eq
    VECTOR(x), LIST(y) -> compare(first, second) == Eq
    LIST(x), VECTOR(y) -> compare(first, second) == Eq
    DICT(x), DICT(y) -> compare(first, second) == Eq
    _, _ -> first == second
  }
}

pub fn bif_eqp(exprs: List(Expr), env: Env) -> Expr {
  let assert [x, ..xs] = exprs
  //let x = uneval(x)
  let x = unwrap(x)
  //let result = case list.all(xs, fn(e) { x == unwrap(e) }) {
  let result = case list.all(xs, fn(e) { is_equal(x, unwrap(e)) }) {
    True -> TRUE
    False -> FALSE
  }
  WithEnv(result, env)
}

pub fn compare_dict(us: List(Expr), vs: List(Expr)) {
  let us = list.sort(us, fn(u, v) { compare(u, v) })
  let vs = list.sort(vs, fn(u, v) { compare(u, v) })
  //dbgout2("us:", us)
  //dbgout2("vs:", vs)
  compare_list(us, vs)
}

pub fn compare_list(us: List(Expr), vs: List(Expr)) {
  case us, vs {
    [], [] -> Eq
    [], _ -> Lt
    _, [] -> Gt
    [u, ..us], [v, ..vs] -> {
      case compare(u, v) {
        Eq -> compare_list(us, vs)
        result -> result
      }
    }
  }
}

pub fn compare(u: Expr, v: Expr) -> Order {
  case u, v {
    INT(u), INT(v) -> int.compare(u, v)
    FLOAT(u), FLOAT(v) -> float.compare(u, v)
    FLOAT(u), INT(v) -> float.compare(u, int.to_float(v))
    INT(u), FLOAT(v) -> float.compare(int.to_float(u), v)
    STRING(u), STRING(v) -> string.compare(u, v)
    SYMBOL(u), SYMBOL(v) -> string.compare(u, v)
    KEYWORD(u), KEYWORD(v) -> string.compare(u, v)
    LIST(us), LIST(vs) -> compare_list(us, vs)
    VECTOR(us), VECTOR(vs) -> compare_list(us, vs)
    VECTOR(us), LIST(vs) -> compare_list(us, vs)
    LIST(us), VECTOR(vs) -> compare_list(us, vs)
    DICT(us), DICT(vs) -> compare_dict(us, vs)
    _, _ -> {
      case u == v {
        True -> Eq
        False -> compare_any(u, v)
      }
    }
  }
}

// (< 1 2 3 4) => true
// リストの前から2つずつ再帰的に比較する
pub fn bif_ltp(exprs: List(Expr), env: Env) -> Expr {
  let result = case exprs {
    [] -> FALSE
    [x] -> TRUE
    [x, y, ..rest] -> {
      case compare(x, y) {
        Lt -> bif_ltp([y, ..rest], env)
        _ -> FALSE
      }
    }
  }
  WithEnv(result, env)
}

// (> 4 3 2 1) => true
// リストの前から2つずつ再帰的に比較する
pub fn bif_gtp(exprs: List(Expr), env: Env) -> Expr {
  let result = case exprs {
    [] -> FALSE
    [x] -> TRUE
    [x, y, ..rest] -> {
      case compare(x, y) {
        Gt -> bif_gtp([y, ..rest], env)
        _ -> FALSE
      }
    }
  }
  WithEnv(result, env)
}

pub fn bif_lteqp(exprs: List(Expr), env: Env) -> Expr {
  let result = case exprs {
    [] -> FALSE
    [x] -> TRUE
    [x, y, ..rest] -> {
      case compare(x, y) {
        Lt | Eq -> bif_lteqp([y, ..rest], env)
        _ -> FALSE
      }
    }
  }
  WithEnv(result, env)
}

pub fn bif_gteqp(exprs: List(Expr), env: Env) -> Expr {
  let result = case exprs {
    [] -> FALSE
    [x] -> TRUE
    [x, y, ..rest] -> {
      case compare(x, y) {
        Gt | Eq -> bif_gteqp([y, ..rest], env)
        _ -> FALSE
      }
    }
  }
  WithEnv(result, env)
}

//pub fn bif_lteqp(exprs: List(Expr), env: Env) -> Expr {
//  let assert WithEnv(result, env) = bif_gtp(exprs, env)
//  let result = case result {
//    TRUE -> FALSE
//    _ -> TRUE
//  }
//  WithEnv(result, env)
//}
//
//pub fn bif_gteqp(exprs: List(Expr), env: Env) -> Expr {
//  let assert WithEnv(result, env) = bif_ltp(exprs, env)
//  let result = case result {
//    TRUE -> FALSE
//    _ -> TRUE
//  }
//  WithEnv(result, env)
//}

pub fn bif_and(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [] -> WithEnv(TRUE, env)
    [x, ..xs] -> {
      case is_true_condition(x) {
        True -> bif_and(xs, env)
        False -> WithEnv(FALSE, env)
      }
    }
  }
}

pub fn bif_or(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [] -> WithEnv(FALSE, env)
    [x, ..xs] -> {
      case is_true_condition(x) {
        False -> bif_or(xs, env)
        True -> WithEnv(TRUE, env)
      }
    }
  }
}

pub fn bif_not(exprs: List(Expr), env: Env) -> Expr {
  let assert [x] = exprs
  case is_true_condition(x) {
    True -> WithEnv(FALSE, env)
    False -> WithEnv(TRUE, env)
  }
}

// (def! Symbol Expr)
pub fn bispform_def(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("**def", exprs)
  let assert [SYMBOL(sym), expr] = exprs
  let assert WithEnv(eexpr, new_env) = eval([expr], UNDEFINED, env)
  let new_env = env_set_global(new_env, sym, eexpr)
  WithEnv(eexpr, new_env)
}

// (erase! Symbol)
pub fn bispform_erase(exprs: List(Expr), env: Env) -> Expr {
  let assert [SYMBOL(sym)] = exprs
  let old_value = env_erase_global(env, sym)
  WithEnv(old_value, env)
}

pub fn global_keys(prefix: String, env: Env) -> List(String) {
  let keys: List(String) = env_get_global_keys(env)
  case prefix {
    "" -> keys
    _ -> list.filter(keys, fn(key) { string.starts_with(key, prefix) })
  }
}

pub fn bif_global_keys(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [] -> {
      WithEnv(LIST(list.map(global_keys("", env), STRING)), env)
    }

    [prefix] -> {
      let prefix = pstr(prefix)
      WithEnv(
        LIST(
          global_keys(prefix, env)
          |> list.map(STRING),
        ),
        env,
      )
    }
    unhandable -> {
      throw_err("unhandable arguments at global_keys")
      WithEnv(UNDEFINED, env)
    }
  }
}

pub fn bif_global_get(exprs: List(Expr), env: Env) -> Expr {
  let assert [name] = exprs
  let name = pstr(uneval(name))
  WithEnv(env_get_global(env, name), env)
}

// // #(eval_env, bind_env)
// fn binds(eval_env: Env, bind_env: Env, bindings: List(Expr)) -> #(Env, Env) {
//   case bindings {
//     [] -> #(eval_env, bind_env)
//     [SYMBOL(sym), expr, ..rest] -> {
//       let assert WithEnv(eexpr, eval_env) = eval([expr], UNDEFINED, bind_env)
//       let bind_env = env_set_local(bind_env, sym, eexpr)
//       binds(eval_env, bind_env, rest)
//     }
//   }
// }

// [key1 val1 key2 val2 ...]
//   (set key1 (eval val1))
//   (set key2 (eval val2))
//   ...
// global以外の変数の変更はないので、オリジナルのeval_envに変化はない。そのため、bind_envのみで処理すれば良い。
fn binds(eval_env: Env, bindings: List(Expr)) -> Env {
  case bindings {
    [] -> eval_env
    [SYMBOL(sym), expr, ..rest] -> {
      let assert WithEnv(eexpr, eval_env) = eval([expr], UNDEFINED, eval_env)
      let eval_env = env_set_local(eval_env, sym, eexpr)
      binds(eval_env, rest)
    }
    unhandable -> {
      throw_err("unhandable bindings")
      eval_env
    }
  }
}

// global変数以外は変更されないので、このlet*の実行でenvは変化しない。
// (let* [Key1 Val1 Key2 Val2 ..] Expr....)
pub fn bispform_let(exprs: List(Expr), env: Env) -> Expr {
  //gdb__ && dbgout1("## let* ################################################")
  let assert [first, ..progn] = exprs
  let assert LIST(let_bindings) = uneval(first)

  // envは現在の環境なので、letの環境を作る
  //  let let_env =
  //    Env(
  //      ..env,
  //      scopes: [Scope(env.local_vars), ..env.scopes],
  //      local_vars: dict.from_list([]),
  //    )

  // let*を実行する環境をそのまま使う
  let let_env = env

  // let_envのlocal scopeに変数を束縛する
  let let_env = binds(let_env, let_bindings)
  let new_local_vars = let_env.local_vars

  let new_local_env =
    Env(..let_env, info: let_env.info, a_binding: new_local_vars)
  //generate_local_env("let", let_env, new_local_vars)

  //dbgout2("### new local vars:", dict.keys(new_local_vars))
  local_continuation(progn, new_local_env, env)
}

fn separate_property(
  body: List(Expr),
  property_name: String,
) -> #(String, List(Expr)) {
  case body {
    [KEYWORD(name), STRING(property_value), ..rest] if property_name == name -> #(
      property_value,
      rest,
    )
    _ -> #("", body)
  }
}

// (fn* [Key1 Key2 ..] Expr....)
// CLOSURE(List(String), List(Expr), Env)
pub fn bispform_fn(exprs: List(Expr), env: Env) -> Expr {
  let assert [first, ..body] = exprs
  let assert LIST(params) = uneval(first)
  //io.println("fn -> CLOSURE")

  let #(name, body) = separate_property(body, "name")
  let #(description_text, body) = separate_property(body, "description")

  let name = case name {
    "" -> unique_str()
    _ -> name
  }

  let closure =
    CLOSURE(
      description_with_text(name, description_text),
      // バインドする引数の名前
      list.map(params, fn(e) {
        case e {
          SYMBOL(sym) -> sym
          _ -> {
            throw_err("invalid parameter")
            ""
          }
        }
      }),
      body,
      // この時点でのenvをクロージャに保存する
      env,
    )

  //gdb__ && dump_closure("NEW FN", closure)

  WithEnv(closure, env)
}

fn closure_to_macro(closure: Expr) -> Expr {
  let assert CLOSURE(name, params, body, closure_env) = closure
  MACRO(name, params, body, closure_env)
}

pub fn bispform_macro(exprs: List(Expr), env: Env) -> Expr {
  let assert WithEnv(closure, new_env) = bispform_fn(exprs, env)
  let macroval = closure_to_macro(closure)
  WithEnv(macroval, env)
}

// (defmacro! Symbol Expr)
pub fn bispform_defmacro(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("**defmacro!", exprs)
  let assert [SYMBOL(sym), expr] = exprs
  let assert WithEnv(eexpr, new_env) = eval([expr], UNDEFINED, env)
  let eexpr = case eexpr {
    MACRO(..) -> {
      eexpr
    }
    CLOSURE(..) -> {
      closure_to_macro(eexpr)
    }

    _ -> {
      throw_err("invalid macro")
      UNDEFINED
    }
  }
  let new_env = env_set_global(new_env, sym, eexpr)
  WithEnv(eexpr, new_env)
}

pub fn bif_car(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("**car", exprs)
  //let assert [LIST([car, ..])] = exprs
  //WithEnv(car, env)
  case exprs {
    [LIST(contents)] | [VECTOR(contents)] | [DICT(contents)] -> {
      case contents {
        [car, ..cdr] -> WithEnv(car, env)
        [] -> WithEnv(NIL, env)
      }
    }
    _ -> {
      //throw_err("invalid car expression")
      WithEnv(NIL, env)
    }
  }
}

// cdrは必ずLISTで返す
pub fn bif_cdr(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  case expr {
    LIST(contents) | VECTOR(contents) | DICT(contents) -> {
      case contents {
        //[_, ..cdr] -> WithEnv(make_container(expr, cdr), env)
        [_, ..cdr] -> WithEnv(LIST(cdr), env)
        //[] -> WithEnv(make_container(expr, []), env)
        [] -> WithEnv(LIST([]), env)
      }
    }
    _ -> {
      //throw_err("invalid cdr expression")
      WithEnv(LIST([]), env)
    }
  }
}

// (cons 1 '(2 3))
pub fn bif_cons(exprs: List(Expr), env: Env) -> Expr {
  //let assert [car, LIST(cdr)] = list.map(exprs, uneval)
  let assert [car, cdr] = exprs
  let car = unwrap(car)
  let cdr = unwrap(cdr)
  let contents = list.append([car], get_contents(cdr))
  WithEnv(LIST(contents), env)
  //WithEnv(make_container(cdr, contents), env)
}

pub fn bif_progn(exprs: List(Expr), env: Env) -> Expr {
  continuation(exprs, env)
}

// (if Condition Then Else)
pub fn bispform_if(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [condition, then, else_clause] -> {
      let assert WithEnv(econdition, new_env) =
        eval([condition], UNDEFINED, env)
      case is_true_condition(econdition) {
        True -> continuation([then], new_env)
        False -> continuation([else_clause], new_env)
      }
    }
    [condition, then] -> {
      let assert WithEnv(econdition, new_env) =
        eval([condition], UNDEFINED, env)
      case is_true_condition(econdition) {
        True -> continuation([then], new_env)
        False -> WithEnv(NIL, new_env)
      }
    }
    _ -> {
      throw_err("invalid if expression")
      WithEnv(UNDEFINED, env)
    }
  }
}

pub fn bif_prn(exprs: List(Expr), env: Env) -> Expr {
  let str = string.join(list.map(exprs, fn(expr) { print(expr) }), " ")
  console_writeln(str)
  WithEnv(NIL, env)
}

pub fn bif_pr_str(exprs: List(Expr), env: Env) -> Expr {
  let str = string.join(list.map(exprs, fn(expr) { print(expr) }), " ")
  console_writeln("\"" <> escape_binary_string(str) <> "\"")
  WithEnv(STRING(str), env)
}

pub fn bif_println(exprs: List(Expr), env: Env) -> Expr {
  let str = string.join(list.map(exprs, fn(expr) { show(expr) }), " ")
  console_writeln(str)
  WithEnv(NIL, env)
}

@target(erlang)
pub fn bif_readline(exprs: List(Expr), env: Env) -> Expr {
  let prompt = case exprs {
    [prompt] -> show(uneval(prompt))
    _ -> ""
  }
  let line = console_readline(prompt)
  WithEnv(STRING(line), env)
}

@target(javascript)
pub fn bif_readline(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(STRING("readline is unsupported"), env)
}

pub fn bif_inspect(exprs: List(Expr), env: Env) -> Expr {
  let assert [first] = exprs
  let str = inspect(uneval(first))
  console_writeln(str)
  WithEnv(NIL, env)
}

pub fn bif_inspect_env(exprs: List(Expr), env: Env) -> Expr {
  dump_env("inspect-env", env)
  WithEnv(NIL, env)
}

pub fn bif_describe(exprs: List(Expr), env: Env) -> Expr {
  let assert [first] = exprs
  let str = describe(uneval(first))
  console_writeln(str)
  WithEnv(NIL, env)
}

pub fn bif_list(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(LIST(exprs), env)
}

pub fn bif_listp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  case expr {
    LIST(_) -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_vec(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  let assert LIST(contents) = uneval(expr)
  WithEnv(VECTOR(contents), env)
}

pub fn bif_vector(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(VECTOR(exprs), env)
}

pub fn bif_vectorp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  case expr {
    VECTOR(_) -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

// (to-hash-map [:a 'alpha :b 'beta])
pub fn bif_to_hash_map(exprs: List(Expr), env: Env) -> Expr {
  let assert [LIST(contents)] = exprs
  WithEnv(DICT(contents), env)
}

// (hash-map :a 'alpha :b 'beta)
pub fn bif_hash_map(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(DICT(exprs), env)
}

pub fn bif_hash_mapp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  case expr {
    DICT(_) -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_emptyp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  WithEnv(to_l4u_bool(is_empty_value(expr)), env)
}

pub fn bif_nilp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  WithEnv(to_l4u_bool(is_nil_value(expr)), env)
}

pub fn bif_truep(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  WithEnv(to_l4u_bool(is_true_value(expr)), env)
}

pub fn bif_falsep(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  WithEnv(to_l4u_bool(!is_true_value(expr)), env)
}

pub fn bif_containsp(exprs: List(Expr), env: Env) -> Expr {
  let assert [container, value] = exprs
  case container, value {
    LIST(contents), _ ->
      WithEnv(to_l4u_bool(list.contains(contents, value)), env)
    DICT(contents), _ ->
      WithEnv(to_l4u_bool(list.contains(contents, value)), env)
    STRING(contents), STRING(value) ->
      WithEnv(to_l4u_bool(string.contains(contents, value)), env)
    _, _ -> WithEnv(FALSE, env)
  }
}

// atom?: Takes an argument and returns true if the argument is an atom.
pub fn bif_atomp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [ATOM(_), ..rest] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_keyword(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [KEYWORD(..) as keyword] -> WithEnv(keyword, env)
    [STRING(str) as keyword] -> WithEnv(intern_keyword(str), env)
    _ -> {
      throw_err("invalid keyword")
      UNDEFINED
    }
  }
}

pub fn bif_keywordp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [KEYWORD(_), ..] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_stringp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [STRING(_), ..] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_numberp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [INT(_), ..] -> WithEnv(TRUE, env)
    [FLOAT(_), ..] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_symbol(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let assert STRING(str) = uneval(expr)
  WithEnv(SYMBOL(str), env)
}

pub fn bif_symbolp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [SYMBOL(_), ..] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_sequentialp(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [LIST(_), ..] | [VECTOR(_), ..] -> WithEnv(TRUE, env)
    _ -> WithEnv(FALSE, env)
  }
}

pub fn bif_fnp(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  let flag = case expr {
    BIF(..) -> TRUE
    CLOSURE(..) -> TRUE
    _ -> FALSE
  }
  WithEnv(flag, env)
}

pub fn bif_macrop(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = unwrap(expr)
  let flag = case expr {
    MACRO(..) -> TRUE
    _ -> FALSE
  }
  WithEnv(flag, env)
}

pub fn bif_count(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [LIST(contents)] | [VECTOR(contents)] | [DICT(contents)] ->
      WithEnv(INT(list.length(contents)), env)
    //_ -> WithEnv(FALSE, env)
    _ -> WithEnv(INT(0), env)
  }
}

// atom: Takes a L4u value and returns a new atom which points to that L4u value.
pub fn bif_atom(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs

  WithEnv(ATOM(make_ref(expr)), env)
}

// deref: Takes an atom argument and returns the L4u value referenced by this atom.
pub fn bif_deref(exprs: List(Expr), env: Env) -> Expr {
  let assert [ATOM(ref)] = exprs
  WithEnv(deref(ref), env)
}

// reset!: Takes an atom and a L4u value; the atom is modified to refer to the given L4u value. The L4u value is returned.
pub fn bif_reset(exprs: List(Expr), env: Env) -> Expr {
  let assert [ATOM(ref), expr] = exprs
  reset_ref(ref, expr)
  WithEnv(expr, env)
}

// (quote x)
pub fn bispform_quote(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("**quote", exprs)
  let assert [expr] = exprs
  WithEnv(expr, env)
}

pub fn make_container(template_expr: Expr, contents: List(Expr)) -> Expr {
  case template_expr {
    LIST(_) -> LIST(contents)
    VECTOR(_) -> VECTOR(contents)
    DICT(_) -> DICT(contents)
    _ -> UNDEFINED
  }
}

pub fn get_contents(expr: Expr) -> List(Expr) {
  case expr {
    LIST(contents) -> contents
    VECTOR(contents) -> contents
    DICT(contents) -> contents
    _ -> []
  }
}

// ----------------------------------------------------------------------------
// # original quasiquote
// ----------------------------------------------------------------------------

pub fn quasiquote_(expr: Expr, env: Env) -> #(List(Expr), Env) {
  //let expr = uneval(expr)
  //dbgout2("**quasiquote::", expr)

  case expr {
    LIST(xs) | VECTOR(xs) -> {
      case xs {
        [sym, expr] if sym == sym_unquote -> {
          //dbgout2("**unquote", expr)
          let assert WithEnv(expr, env) = eval([expr], UNDEFINED, env)
          #([expr], env)
        }
        [sym, expr] if sym == sym_unquote_splicing -> {
          //dbgout2("**unquote-splicing", expr)
          let assert WithEnv(eexpr, env) = eval([expr], UNDEFINED, env)
          #(get_contents(eexpr), env)
        }
        exprs -> {
          let #(new_env, lst) =
            list.fold(exprs, #(env, []), fn(state, x) {
              let #(env, acc) = state
              let assert #(exprs, new_env) = quasiquote_(x, env)
              #(new_env, list.append(acc, exprs))
            })
          //dbgout2("LIST quasiquote:", lst)
          #([make_container(expr, lst)], new_env)
        }
      }
    }
    _ -> {
      #([expr], env)
    }
  }
}

pub fn bispform_quasiquote(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("****quasiquote::", exprs)

  let assert [expr] = exprs
  let assert #([eexpr], new_env) = quasiquote_(expr, env)
  WithEnv(eexpr, new_env)
}

pub fn bispform_quasiquote_expand(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let assert #([eexpr], new_env) = quasiquote_(expr, env)
  WithEnv(eexpr, new_env)
}

// ----------------------------------------------------------------------------
// # l4u quasiquote
// ----------------------------------------------------------------------------
fn unquote_special(expr: Expr) -> Expr {
  case expr {
    LIST([SYMBOL("quote"), NIL]) -> NIL
    LIST(exprs) -> {
      LIST(list.map(exprs, unquote_special))
    }
    _ -> expr
  }
}

fn qq_loop(elt: Expr, acc: Expr) {
  case elt {
    LIST([SYMBOL("splice-unquote"), arg]) ->
      LIST(list.append([SYMBOL("concat"), arg], [acc]))
    _ -> LIST(list.append([SYMBOL("cons"), quasiquote(elt)], [acc]))
  }
}

fn quasiquote(ast: Expr) -> Expr {
  //dbgout2("quasiquote2:", ast)
  case ast {
    LIST([SYMBOL("unquote"), arg]) -> arg
    LIST(l) -> list.fold_right(l, LIST([]), fn(acc, x) { qq_loop(x, acc) })
    VECTOR(l) ->
      LIST([
        SYMBOL("vec"),
        list.fold_right(l, LIST([]), fn(acc, x) { qq_loop(x, acc) }),
      ])
    SYMBOL(_) | DICT(_) -> LIST([SYMBOL("quote"), ast])
    _ -> ast
  }
}

pub fn bispform_quasiquote2(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let eexpr = quasiquote(expr)
  //eval([eexpr], UNDEFINED, env)
}

pub fn bispform_quasiquote_expand2(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let eexpr = quasiquote(expr)
  //dbgout2("quasiquote expand2:", eexpr)
  WithEnv(eexpr, env)
}

//pub fn bispform_quasiquote_expand_x(exprs: List(Expr), env: Env) -> Expr {
//  let assert WithEnv(e1, env1) = bispform_quasiquote_expand(exprs, env)
//  let assert WithEnv(e2, env2) = bispform_quasiquote_expand2(exprs, env)
//  dbgout2("** e1:", e1)
//  dbgout2("** e2:", e2)
//  WithEnv(e2, env2)
//}

pub fn get_macro(env: Env, ast: Expr) -> Result(Expr, String) {
  case ast {
    LIST([SYMBOL(sym), ..]) -> {
      case env_get(env, sym) {
        Ok(MACRO(..) as macroval) -> Ok(macroval)
        _ -> Error("not macro")
      }
    }
    _ -> Error("not macro")
  }
}

pub fn macroexpand(env: Env, ast: Expr) -> Expr {
  case get_macro(env, ast) {
    Ok(macroval) -> {
      apply_macro_1(macroval, env)
    }
    _ -> ast
  }
}

pub fn macroexpand_all(env: Env, ast: Expr) -> Expr {
  case get_macro(env, ast) {
    Ok(macroval) -> {
      apply_macro(macroval, env)
    }
    _ -> ast
  }
}

// exprsを渡された時点で、すでにマクロは展開されている
pub fn bispform_macroexpand(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = macroexpand(env, expr)
  WithEnv(expr, env)
}

pub fn bispform_macroexpand_all(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  let expr = macroexpand_all(env, expr)
  WithEnv(expr, env)
}

pub fn bif_load_file(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(filename)] = exprs
  let contents = load_file(filename)
  //dbgout2("load_file:", "<<" <> contents <> ">>")
  let assert WithEnv(_rexpr, new_env) = rep(contents, env)
  WithEnv(NIL, new_env)
}

pub fn bif_slurp(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(filename)] = exprs
  let contents = load_file(filename)
  //dbgout2("load_file:", "<<" <> contents <> ">>")
  WithEnv(STRING(contents), env)
}

pub fn bif_read_string(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(str)] = exprs
  let exprs = read(str, env)
  let assert [expr, ..] = exprs
  //WithEnv(LIST(exprs), env)
  WithEnv(expr, env)
}

pub fn bif_tokenize(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  let tokenized = tokenize(src, env)
  dbgout2("tokenize:", tokenized)
  WithEnv(LIST(list.map(tokenized, fn(i) { STRING(i) })), env)
}

pub fn bif_read(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(src)] = exprs
  //WithEnv(LIST(read(src, env)), env)
  let assert [expr] = read(src, env)
  WithEnv(expr, env)
}

pub fn bif_eval(exprs: List(Expr), env: Env) -> Expr {
  //let assert [STRING(src)] = exprs
  eval(exprs, UNDEFINED, env_get_toplevel(env))
}

pub fn apply(env: Env, callable: Expr, args: List(Expr)) -> Expr {
  eval([LIST(list.append([callable], args))], UNDEFINED, env)
}

// (apply f args)
//pub fn bif_apply(exprs: List(Expr), env: Env) -> Expr {
//  let assert [callable, LIST(args)] = exprs
//  eval([LIST(list.append([callable], args))], UNDEFINED, env)
//}

fn funcall(callable: Expr, eargs: List(Expr), new_env: Env) -> Expr {
  //dbgout2("*** funcall:", callable)
  case callable {
    BIF(_, f) -> {
      f(eargs, new_env)
    }
    CLOSURE(name, params, progn, closure_env) -> {
      // closureに渡す引数を評価する
      let bindings = bind_args(dict.from_list([]), params, eargs)

      let new_closure_env =
        //  Env(
        //    ..closure_env,
        //    //info: Info(..closure_env.info),
        //    local_vars: dict.merge(bindings, closure_env.local_vars),
        //  )
        generate_local_env("funcall", closure_env, bindings, new_env.a_binding)

      local_continuation(progn, new_closure_env, new_env)
    }
    _ -> {
      throw_err("invalid function")
      UNDEFINED
    }
  }
}

pub fn bif_apply(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("apply:", exprs)
  let assert [callable, ..rest_args] = exprs
  let assert Ok(last_args) = list.last(rest_args)
  //dbgout2("last_args:", last_args)
  let assert LIST(last_args) = uneval(last_args)
  //dbgout2("last_args:", last_args)
  let #(args, _) = list.split(rest_args, list.length(rest_args) - 1)
  //dbgout2("args:", args)

  //let fncall = LIST(list.concat([[callable], args, last_args]))
  let fnargs = list.concat([args, last_args])
  //dbgout2("fncall:", fnargs)

  //eval([fncall], UNDEFINED, env)
  funcall(callable, fnargs, env)
}

//pub fn bsf_apply(exprs: List(Expr), env: Env) -> Expr {
//  //dbgout2("apply:", exprs)
//  let assert [callable, ..rest_args] = exprs
//  let assert Ok(last_args) = list.last(rest_args)
//  let assert LIST(last_args) = uneval(last_args)
//  dbgout2("last_args:", last_args)
//  let #(args, _) = list.split(rest_args, list.length(rest_args) - 1)
//  dbgout2("args:", args)
//
//  let fncall = LIST(list.concat([[callable], args, last_args]))
//  dbgout2("fncall:", fncall)
//
//  eval([fncall], UNDEFINED, env)
//}

// (try* A... (catch* B C...))
pub fn bispform_try(exprs: List(Expr), env: Env) -> Expr {
  let assert try_exprs = exprs
  case list.last(try_exprs) {
    Ok(LIST([SYMBOL("catch*"), SYMBOL(bind_to), ..catch_exprs])) -> {
      let try_exprs = list.take(try_exprs, list.length(try_exprs) - 1)

      let try_result =
        catch_ex(fn() {
          let assert WithEnv(ret_expr, new_env) as res =
            eval(try_exprs, UNDEFINED, env)
          res
        })
      //dbgout2("try_result:", try_result)
      case try_result {
        Ok(result) -> result
        Error(exexpr) ->
          local_continuation(
            catch_exprs,
            //env_set_local(env, bind_to, STRING(exexpr)),
            env_set_local(env, bind_to, exexpr),
            env,
          )
      }
    }

    _ -> {
      eval(try_exprs, UNDEFINED, env)
    }
  }
}

pub fn bif_throw(exprs: List(Expr), env: Env) -> Expr {
  let assert [expr] = exprs
  throw_expr(expr)
  WithEnv(UNDEFINED, env)
}

pub fn bif_meta(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [WithMeta(expr, meta)] -> WithEnv(meta, env)
    _ -> WithEnv(NIL, env)
  }
}

pub fn bif_with_meta(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [WithMeta(expr, meta), new_meta] -> WithEnv(WithMeta(expr, new_meta), env)
    [expr, new_meta] -> WithEnv(WithMeta(expr, new_meta), env)
    _ -> {
      throw_err("invalid with-meta")
      UNDEFINED
    }
  }
}

// ----------------------------------------------------------------------------
// # hashmap
// ----------------------------------------------------------------------------

pub fn plist_to_map(
  plist: List(Expr),
  acc: Dict(String, Expr),
) -> Dict(String, Expr) {
  //dbgout2("plist_to_map:", plist)
  case plist {
    [] -> acc
    [key, value, ..rest] -> {
      let acc = dict.insert(acc, pstr(key), value)
      plist_to_map(rest, acc)
    }
    _ -> {
      throw_err("plist_to_map: invalid plist")
      acc
    }
  }
}

pub fn map_to_plist(mapdata: Dict(String, Expr), acc: List(Expr)) -> List(Expr) {
  map_to_plist_(dict.to_list(mapdata), [])
}

fn map_to_plist_(plist: List(#(String, Expr)), acc: List(Expr)) -> List(Expr) {
  case plist {
    [] -> acc
    [#(key, value), ..rest] -> {
      map_to_plist_(rest, [intern_keyword(key), value, ..acc])
    }
    _ -> {
      throw_err("invalid map")
      acc
    }
  }
}

fn assoc(plist: List(Expr), entries: List(Expr)) -> List(Expr) {
  let assoc_keys = dict_keys(entries, [])
  let dissoced_plist = dissoc(plist, assoc_keys, [])
  //dbgout2("dissoced entries:", dissoced_dict)
  let new_plist = list.append(dissoced_plist, entries)
}

// assoc", bif_assoc),
pub fn bif_assoc(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("assoc:", exprs)
  let assert [DICT(dict), ..entries] = exprs
  // //dbgout2("entries:", dict)
  // let assoc_keys = dict_keys(entries, [])
  // let dissoced_dict = dissoc(dict, assoc_keys, [])
  // //dbgout2("dissoced entries:", dissoced_dict)
  // let new_dict = DICT(list.append(dissoced_dict, entries))
  let new_dict = DICT(assoc(dict, entries))
  WithEnv(new_dict, env)
}

fn dissoc(plist: List(Expr), keys: List(Expr), acc: List(Expr)) -> List(Expr) {
  case plist {
    [] -> list.reverse(acc)
    [key, value, ..rest] -> {
      case list.contains(keys, key) {
        True -> dissoc(rest, list.filter(keys, fn(k) { k != key }), acc)
        _ -> dissoc(rest, keys, [value, key, ..acc])
      }
    }
    _ -> {
      throw_err("dissoc: invalid plist")
      list.reverse(acc)
    }
  }
}

// dissoc", bif_dissoc),
pub fn bif_dissoc(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("dissoc:", exprs)
  let assert [DICT(dict), ..keys] = exprs
  let new_dict = DICT(dissoc(dict, keys, []))
  WithEnv(new_dict, env)
}

fn search_dict(plist: List(Expr), key: Expr) -> Expr {
  case plist {
    [] -> NIL
    [ekey, evalue, ..erest] if ekey == key -> {
      evalue
    }
    [ekey, evalue, ..erest] -> {
      search_dict(erest, key)
    }
    _ -> {
      throw_err("search_dict: invalid plist")
      NIL
    }
  }
}

// get", bif_get),
pub fn bif_get(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [DICT(dict), key] -> WithEnv(search_dict(dict, key), env)
    _ -> WithEnv(NIL, env)
  }
}

fn dict_keys(plist: List(Expr), acc: List(Expr)) -> List(Expr) {
  case plist {
    [] -> list.reverse(acc)
    [key, value, ..rest] -> {
      dict_keys(rest, [key, ..acc])
    }
    _ -> {
      throw_err("dict_keys: invalid plist")
      []
    }
  }
}

// keys", bif_keys),
pub fn bif_keys(exprs: List(Expr), env: Env) -> Expr {
  let assert [DICT(dict)] = exprs
  WithEnv(LIST(dict_keys(dict, [])), env)
}

fn dict_vals(plist: List(Expr), acc: List(Expr)) -> Expr {
  case plist {
    [] -> LIST(list.reverse(acc))
    [key, value, ..rest] -> {
      dict_vals(rest, [value, ..acc])
    }
    _ -> {
      throw_err("dict_vals: invalid plist")
      UNDEFINED
    }
  }
}

// vals", bif_vals),
pub fn bif_vals(exprs: List(Expr), env: Env) -> Expr {
  let assert [DICT(dict)] = exprs
  WithEnv(dict_vals(dict, []), env)
}

pub fn bif_gensym(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(SYMBOL("$" <> int.to_string(unique_int())), env)
}

@target(erlang)
pub fn bif_time_ms(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(INT(tick_count() / 1_000_000), env)
}

@target(javascript)
pub fn bif_time_ms(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(INT(tick_count()), env)
}

pub fn bif_str(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(
    STRING(
      list.map(exprs, fn(expr) { show(expr) })
      |> string.join(""),
    ),
    env,
  )
}

pub fn bif_show(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(
    STRING(
      list.map(exprs, fn(expr) { show(expr) })
      |> string.join(""),
    ),
    env,
  )
}

fn trace(env: Env, exprs: List(Expr), tron: Bool) -> Env {
  case exprs {
    [] -> env

    [LIST(fnnames), ..rest] -> {
      trace(env, fnnames, tron)
      trace(env, rest, tron)
    }

    [KEYWORD(fnname) as expr, ..rest] -> {
      case env_get_global(env, fnname) {
        CLOSURE(name, params, body, closure_env) -> {
          env_set_global(
            env,
            fnname,
            CLOSURE(
              name,
              params,
              body,
              Env(
                ..closure_env,
                opts: EnvOptions(..closure_env.opts, trace: tron),
              ),
            ),
          )
          env
        }
        _ -> {
          env
        }
      }

      trace(env, rest, tron)
    }

    _ -> {
      env
    }
  }
}

// (trace fn1 fn2 ...)
pub fn bif_trace(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(NIL, trace(env, exprs, True))
}

pub fn bif_trace_clear(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(NIL, trace(env, exprs, False))
}

// ----------------------------------------------------------------------------
// # custom type
// ----------------------------------------------------------------------------

// #カスタムタイプを定義する
// (def-custom-type Name DEFINITION_STRUCT)
pub fn bif_def_custom_type(exprs: List(Expr), env: Env) -> Expr {
  let assert [name, struct_def] = exprs
  let name = pstr(unwrap(name))
  let struct_def = unwrap(struct_def)
  let custom_type_def = CustomTypeDef(name, struct_def)
  let new_env = env_set_global(env, name, custom_type_def)
  WithEnv(custom_type_def, new_env)
}

fn instanciate_custom_type(cdef: Expr, mapdata: Dict(String, Expr)) -> Expr {
  case uneval(cdef) {
    LIST([]) -> {
      LIST([])
    }

    LIST(xs) -> {
      LIST(list.map(xs, fn(x) { instanciate_custom_type(x, mapdata) }))
    }

    KEYWORD(key) -> {
      //dbgout2("KEYWORD:", key)
      case dict.get(mapdata, key) {
        Ok(value) -> value
        _ -> {
          throw_err("invalid custom type")
          UNDEFINED
        }
      }
    }

    any_value -> any_value
  }
}

// #カスタムタイプをインスタンス化する
// (instanciate-custom-type Name DICT)
pub fn bif_instanciate_custom_type(exprs: List(Expr), env: Env) -> Expr {
  let assert [name, mapdata] = exprs
  let name = pstr(unwrap(name))

  let plist = case mapdata {
    LIST(plist) | VECTOR(plist) | DICT(plist) -> plist
    _ -> {
      dbgout2("invalid custom type:", mapdata)
      throw_err("invalid custom type")
      []
    }
  }

  let mapdata = plist_to_map(plist, dict.from_list([]))

  let assert CustomTypeDef(_, custom_type_def) = env_get_global(env, name)
  let instance = instanciate_custom_type(custom_type_def, mapdata)
  WithEnv(CustomType(name, instance), env)
}

// #カスタムタイプをDICTに変換する
// (custom-type-to-map Name VALUE_STRUCT)
fn custom_type_to_map(
  cdef: Expr,
  cval: Expr,
  acc: Dict(String, Expr),
) -> Dict(String, Expr) {
  case uneval(cdef), uneval(cval) {
    LIST([]), LIST([]) -> {
      acc
    }

    LIST([key, ..rest_key]), LIST([val, ..rest_val]) -> {
      let new_map = custom_type_to_map(key, val, acc)
      custom_type_to_map(LIST(rest_key), LIST(rest_val), new_map)
    }

    key, val -> {
      dict.insert(acc, pstr(key), val)
    }
  }
}

// #カスタムタイプをDICTに変換する
// (custom-type-to-map Name VALUE_STRUCT)
pub fn bif_custom_type_to_map(exprs: List(Expr), env: Env) -> Expr {
  let assert [value] = exprs
  let assert CustomType(name, custom_type_value) = value
  let assert CustomTypeDef(_, custom_type_def) = env_get_global(env, name)
  let mapdata =
    custom_type_to_map(custom_type_def, custom_type_value, dict.from_list([]))
  let plist = map_to_plist(mapdata, [])
  WithEnv(DICT(plist), env)
}

// ----------------------------------------------------------------------------
// # Env
// ----------------------------------------------------------------------------

pub fn generate_new_env(
  pdic: PDic,
  default_bindings: Dict(String, Expr),
  init_files,
) -> Env {
  //dbgout2("default_bindings:", default_bindings)

  process_dict_set(pdic, "*trace_ip", 0)
  process_dict_set(pdic, "*trace_level", 0)
  let assert Ok(regexp) =
    regex.compile(
      pattern,
      regex.Options(case_insensitive: False, multi_line: False),
    )
  process_dict_set(pdic, "*regex", regexp)

  // #debug
  //let opts = EnvOptions(verbose: True, trace: True)

  // #release
  let opts = EnvOptions(verbose: gverbose__, trace: False)

  let default_scopes = case bif_to_global_scope__ {
    True -> {
      // default bindings to process dictionary
      dict.map_values(default_bindings, fn(k, v) {
        process_dict_set(pdic, k, v)
      })
      [ProcessDict(pdic)]
    }

    _ -> {
      [ProcessDict(pdic), Scope(default_bindings)]
    }
  }

  let env =
    Env(
      info: Info("toplevel", 0),
      pdic: pdic,
      local_vars: dict.from_list([]),
      a_binding: dict.from_list([]),
      scopes: default_scopes,
      opts: opts,
    )

  let env =
    list.fold(init_files, env, fn(env, file) {
      gdb__
      && {
        io.println("- init " <> file)
        True
      }

      case
        catch_ex(fn() {
          let initialize = load_file(file)
          //dbgout2("initialize:", initialize)
          let assert WithEnv(_, new_env) = rep(initialize, env)
          new_env
        })
      {
        Ok(new_env) -> new_env
        Error(exexpr) -> {
          //dbgout2("init error:", exexpr)
          dbgout2("init error:", error_to_string(exexpr, True))
          env
        }
      }
    })
  //dbgout2("toplevel env:", dump_local_vars(env) <> dump_scopes_keys(env.scopes))
  process_dict_set(pdic, "*toplevel*", env)
  env
}

pub fn make_new_l4u_core_env(
  pdic: PDic,
  bifs: List(#(String, Expr)),
  files: List(String),
) -> Env {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  // default BIF table
  let default_bindings =
    list.append(
      [
        #("*host-language*", host_language),
        bif("+", bif_add),
        bif("-", bif_sub),
        bif("*", bif_mul),
        bif("/", bif_div),
        bif("mod", bif_mod),
        bif("=", bif_eqp),
        bif("eq?", bif_eqp),
        bif("<", bif_ltp),
        bif(">", bif_gtp),
        bif("<=", bif_lteqp),
        bif(">=", bif_gteqp),
        bif("and", bif_and),
        bif("or", bif_or),
        bif("not", bif_not),
        bsf("def!", bispform_def),
        bsf("erase!", bispform_erase),
        bif("global-keys", bif_global_keys),
        bif("global-get", bif_global_get),
        bsf("let*", bispform_let),
        bsf("fn*", bispform_fn),
        bsf("macro*", bispform_macro),
        bsf("defmacro!", bispform_defmacro),
        bif("car", bif_car),
        bif("cdr", bif_cdr),
        bif("cons", bif_cons),
        bsf("do", bif_progn),
        bsf("if", bispform_if),
        bif("prn", bif_prn),
        bif("pr-str", bif_pr_str),
        bif("println", bif_println),
        bif("readline", bif_readline),
        bif("list", bif_list),
        bif("list?", bif_listp),
        bif("vec", bif_vec),
        bif("vector", bif_vector),
        bif("vector?", bif_vectorp),
        bif("to-hash-map", bif_to_hash_map),
        bif("hash-map", bif_hash_map),
        bif("hash-map?", bif_hash_mapp),
        bif("map?", bif_hash_mapp),
        bif("empty?", bif_emptyp),
        bif("nil?", bif_nilp),
        bif("true?", bif_truep),
        bif("false?", bif_falsep),
        bif("contains?", bif_containsp),
        bif("atom?", bif_atomp),
        bif("keyword", bif_keyword),
        bif("keyword?", bif_keywordp),
        bif("string?", bif_stringp),
        bif("number?", bif_numberp),
        bif("symbol", bif_symbol),
        bif("symbol?", bif_symbolp),
        bif("sequential?", bif_sequentialp),
        bif("fn?", bif_fnp),
        bif("macro?", bif_macrop),
        bif("count", bif_count),
        bif("atom", bif_atom),
        bif("deref", bif_deref),
        bif("reset!", bif_reset),
        bsf("quote", bispform_quote),
        bsf("quasiquote0", bispform_quasiquote),
        bsf("quasiquote", bispform_quasiquote2),
        bsf("quasiquoteexpand0", bispform_quasiquote_expand),
        bsf("quasiquoteexpand", bispform_quasiquote_expand2),
        //bsf("quasiquoteexpand-X", bispform_quasiquote_expand_x),
        bsf("macroexpand", bispform_macroexpand),
        bsf("macroexpand-all", bispform_macroexpand_all),
        bif("load-file", bif_load_file),
        bif("slurp", bif_slurp),
        bif("read-string", bif_read_string),
        bif("tokenize", bif_tokenize),
        bif("read", bif_read),
        bif("eval", bif_eval),
        bif("apply", bif_apply),
        //bsf("apply", bsf_apply),
        bsf("try*", bispform_try),
        bif("throw", bif_throw),
        bif("meta", bif_meta),
        bif("with-meta", bif_with_meta),
        bif("assoc", bif_assoc),
        bif("dissoc", bif_dissoc),
        bif("get", bif_get),
        bif("keys", bif_keys),
        bif("vals", bif_vals),
        bif("gensym", bif_gensym),
        bif("time-ms", bif_time_ms),
        bif("str", bif_str),
        bif("show", bif_show),
        //
        #("true", TRUE),
        #("false", FALSE),
        #("nil", NIL),
        #("undefined", UNDEFINED),
        // debug/trace
        bsf("trace", bif_trace),
        bsf("trace-clear", bif_trace_clear),
        bif("inspect", bif_inspect),
        bif("inspect-env", bif_inspect_env),
        bif("describe", bif_describe),
        // custom type
        bif("def-custom-type", bif_def_custom_type),
        bif("instanciate-custom-type", bif_instanciate_custom_type),
        bif("custom-type-to-map", bif_custom_type_to_map),
      ],
      bifs,
    )
    |> dict.from_list

  let init_files =
    list.append(["default0.lisp", "default1.lisp", "prelude.lisp"], files)

  generate_new_env(pdic, default_bindings, init_files)
}

pub fn env_get_toplevel(env: Env) -> Env {
  process_dict_get(env.pdic, "*toplevel*")
}

fn env_get_(scopes: List(Scope), key: String) -> Result(Expr, String) {
  let assert [target_scope, ..rest_scopes] = scopes

  case target_scope {
    Scope(bindings: bindings) -> {
      case dict.get(bindings, key) {
        Ok(value) -> {
          //dbgout3("env_get -> found:", key, value)
          Ok(value)
        }
        Error(_) -> {
          case rest_scopes {
            [] -> {
              //dbgout2("env_get -> notfound:", key)
              Error("not found:: " <> key)
            }
            _ -> env_get_(rest_scopes, key)
          }
        }
      }
    }
    ProcessDict(pdic) -> {
      case process_dict_get(pdic, key) {
        UNDEFINED -> {
          case rest_scopes {
            [] -> {
              //dbgout2("env_get -> notfound:", key)
              Error("not found:: " <> key)
            }
            _ -> {
              //dbgout2("env_get search next scope:", key)
              env_get_(rest_scopes, key)
            }
          }
        }
        value -> {
          //dbgout3("env_get -> found at process dict:", key, value)
          Ok(value)
        }
      }
    }
  }
}

pub fn env_get(env: Env, key: String) -> Result(Expr, String) {
  case dict.get(env.local_vars, key) {
    Ok(value) -> {
      //dbgout3("env_get found: ", key, value)
      Ok(value)
    }
    Error(_) -> {
      //dbgout2("env_get: ", key)
      //env_get_(env.scopes, key)
      case dict.get(env.a_binding, key) {
        Ok(value) -> {
          Ok(value)
        }
        Error(_) -> {
          env_get_(env.scopes, key)
        }
      }
    }
  }
}

pub fn env_set_local(env: Env, key: String, value: Expr) -> Env {
  Env(..env, local_vars: dict.insert(env.local_vars, key, value))
}

//pub fn env_set_local(env: Env, key: String, value: Expr) -> Env {
//  case env.scopes {
//    [Scope(bindings: local_bindings) as local_scope, ..rest_scopes] -> {
//      let new_bindings = dict.insert(local_bindings, key, value)
//      Env(..env, scopes: [Scope(new_bindings), ..rest_scopes])
//    }
//    _ -> {
//      Error("set error:: " <> key)
//      env
//    }
//  }
//}

pub fn env_add_local_scope(env: Env, scope: Scope) -> Env {
  Env(..env, scopes: [scope, ..env.scopes])
}

pub fn env_replace_local_scope(env: Env, scope: Scope) -> Env {
  case env.scopes {
    [_discard_scope, ..rest_scopes] -> {
      Env(..env, scopes: [scope, ..rest_scopes])
    }
    _ -> {
      Env(..env, scopes: [scope])
    }
  }
}

//pub fn env_set_global(env: Env, key: String, value: Expr) -> Env {
//  let assert Ok(global_scope) = list.last(env.scopes)
//  let new_bindings = dict.insert(global_scope.bindings, key, value)
//  let new_global = Scope(bindings: new_bindings)
//  let new_scopes = case list.reverse(env.scopes) {
//    [] -> [new_global]
//    [_, ..rest] -> {
//      list.reverse([new_global, ..rest])
//    }
//  }
//  Env(..env, scopes: new_scopes)
//}

pub fn get_bif_result_value(expr: Expr) -> any {
  let assert WithEnv(value, _) = expr
  unsafe_corece(value)
}

pub fn env_update_global_aux(
  env: Env,
  key: String,
  property_name: Expr,
  property_value: Expr,
) -> Nil {
  let auxpdic = aux_pdic(env.pdic, "aux")

  case process_dict_get(auxpdic, key) {
    DICT(dict) -> {
      process_dict_set(
        auxpdic,
        key,
        DICT(assoc(dict, [property_name, property_value])),
      )
    }
    _ -> {
      process_dict_set(auxpdic, key, DICT([property_name, property_value]))
    }
  }
  Nil
}

pub fn env_set_global(env: Env, key: String, value: Expr) -> Env {
  process_dict_set(env.pdic, key, value)

  env_update_global_aux(
    env,
    key,
    intern_keyword("time"),
    get_bif_result_value(bif_time_ms([], env)),
  )
  env
}

pub fn env_get_global_aux(env: Env, key: String) -> Expr {
  let auxpdic = aux_pdic(env.pdic, "aux")

  case process_dict_get(auxpdic, key) {
    DICT(..) as dict -> {
      dict
    }
    _ -> UNDEFINED
  }
}

pub fn env_get_global(env: Env, key: String) -> Expr {
  process_dict_get(env.pdic, key)
}

pub fn env_erase_global(env: Env, key: String) -> Expr {
  process_dict_erase(env.pdic, key)
}

pub fn env_get_global_keys(env: Env) {
  process_dict_keys(env.pdic)
}

// ----------------------------------------------------------------------------
// # utilities
// ----------------------------------------------------------------------------
pub fn dump_dict(dict: Dict(String, Expr), env: Env) -> Bool {
  list.each(dict.to_list(dict), fn(item) {
    let #(k, v) = item
    dbgout1(inspect(STRING(k)) <> " => " <> inspect(v))
  })
  False
}

pub fn dump_env(title: String, env: Env) -> Bool {
  dbgout1(
    "--------------------------------------------------------------------",
  )
  dbgout1("# dump_env: " <> title <> " " <> info_to_str(env.info))
  dbgout2(
    "$$eval_expr_$$:",
    dump_local_vars(env) <> dump_scopes_keys(env.scopes),
  )
  False
}

pub fn dump_closure(msg: String, expr: Expr) -> Bool {
  let assert CLOSURE(desc, params, progn, closure_env) = expr
  dbgout1(
    "--------------------------------------------------------------------",
  )
  dbgout1("# dump_closure: " <> msg <> " " <> desc.name)
  dbgout2("params:", params)
  dbgout2("progn:", progn)
  dbgout2(
    "closure_env:",
    dump_local_vars(closure_env) <> dump_scopes_keys(closure_env.scopes),
  )
  False
}

fn dump_local_vars(env: Env) {
  "< " <> vars_to_string(env.local_vars) <> " >"
}

fn dump_scopes_keys(scopes: List(Scope)) -> String {
  case scopes {
    [] -> ""
    [Scope(bindings)] -> "(**)"
    [Scope(bindings), ..rest] -> {
      "["
      <> string.join(dict.keys(bindings), ",")
      <> "]"
      <> dump_scopes_keys(rest)
    }
    [_, ..rest] -> dump_scopes_keys(rest)
  }
}

fn name_of(expr: Expr) -> String {
  case expr {
    LIST([SYMBOL(name), ..]) -> name
    SYMBOL(name) -> name
    BIF(desc, _) -> "bif-" <> desc.name
    CLOSURE(..) -> "closure-" <> "closure"
    MACRO(..) -> "macro-" <> "closure"
    _ -> "?"
  }
}

pub fn trace_set_last_expr(expr: Expr, env: Env) -> Bool {
  process_dict_set(env.pdic, "last_expr", expr)
  False
}

pub fn trace_set_last_funcall(expr: Expr, env: Env) -> Bool {
  process_dict_set(env.pdic, "last_funcall", expr)

  //dump_env("$$funcall$$:" <> name_of(expr), env)
  False
}

pub fn to_simple_str(expr: Expr) -> String {
  case expr {
    SYMBOL(name) -> name
    STRING(name) -> name
    KEYWORD(name) -> name
    INT(value) -> int.to_string(value)
    TRUE -> "true"
    FALSE -> "false"
    NIL -> "nil"
    UNDEFINED -> "undefined"
    _ -> "*"
  }
}

pub fn args_to_str(args: List(Expr)) -> String {
  string.join(list.map(args, fn(arg) { to_simple_str(arg) }), " ")
}

pub fn dict_to_str(dict: Dict(String, Expr)) -> String {
  string.join(
    dict.to_list(dict)
      |> list.map(fn(item) {
        let #(k, v) = item
        to_simple_str(STRING(k)) <> ":" <> to_simple_str(v)
      }),
    ", ",
  )
}

pub fn indent(level: Int) {
  case level > 60 {
    True -> string.repeat(" ", 60)
    _ -> string.repeat(" ", level)
  }
}

pub fn local_scopes_to_string(scopes: List(Scope), acc: List(String)) -> String {
  case scopes {
    [Scope(bindings: bindings), ..rest] -> {
      local_scopes_to_string(rest, [vars_to_string(bindings), ..acc])
    }
    _ -> string.join(list.reverse(acc), " ")
  }
}

pub fn vars_to_string(vars: Dict(String, Expr)) -> String {
  dict.to_list(vars)
  |> list.map(fn(item) {
    let #(k, v) = item
    to_simple_str(STRING(k)) <> ":" <> to_simple_str(v)
  })
  |> string.join(", ")
}

pub fn trace_closure_call(env: Env, callable, ecallable, bindings) -> Int {
  let ip = process_dict_get(env.pdic, "*trace_ip")
  let level = process_dict_get(env.pdic, "*trace_level")

  gdb__
  && env.opts.trace
  && {
    io.println(
      indent(level)
      <> "- "
      <> int.to_string(ip)
      <> ": ("
      <> to_simple_str(callable)
      <> " "
      <> dict_to_str(bindings)
      <> ")",
    )
    // <> dump_local_vars(env) <> " " <> dump_scopes_keys(env.scopes) <> " ",
    True
  }

  process_dict_set(env.pdic, "*trace_level", level + 1)
  process_dict_set(env.pdic, "*trace_ip", ip + 1)
  ip
}

pub fn trace_closure_return(env: Env, callable, ecallable, rexpr, ip: Int) {
  let level = process_dict_get(env.pdic, "*trace_level") - 1
  process_dict_set(env.pdic, "*trace_level", level)

  gdb__
  && env.opts.trace
  && {
    io.println(
      indent(level)
      <> "- "
      <> int.to_string(ip)
      <> ": "
      <> to_simple_str(callable)
      <> " returned "
      <> to_simple_str(rexpr),
    )
    True
  }
}

pub fn info_to_str(inf: Info) {
  case inf {
    Info(name, level) -> {
      name <> ": " <> int.to_string(level)
    }
  }
}

// ----------------------------------------------------------------------------
// # REPL
// ----------------------------------------------------------------------------

pub fn rep(src: String, env: Env) -> Expr {
  let result = eval(read(src, env), UNDEFINED, env)
  result
}

@target(javascript)
pub fn repl(env: Env, prompt: String) {
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
pub fn repl(env: Env, prompt: String) {
  gdb__ && trace_set_last_funcall(UNDEFINED, env)
  let line = console_readline(prompt)
  case string.length(string.trim(line)) {
    0 -> {
      console_writeln("")
      repl(env, prompt)
    }
    _ -> {
      let result =
        catch_ex(fn() {
          process_dict_set(env.pdic, "*trace_ip", 0)
          let assert WithEnv(result, new_env) = rep(line, env)

          repl_print(result)
          new_env
        })

      repl_loop(env, result, prompt)
    }
  }
}

pub fn repl_print(result: Expr) {
  case result {
    PRINTABLE(STRING("")) -> {
      Nil
    }
    PRINTABLE(printable) -> {
      console_writeln(show(result))
    }
    _ -> {
      console_writeln(print(result))
    }
  }
  // debug
  //console_writeln(inspect(result))
}

fn repl_loop(env: Env, result: Result(Env, Expr), prompt: String) {
  // DEBUG
  //bif_inspect_env([], env)

  case result {
    Ok(new_env) -> repl(new_env, prompt)
    Error(err) -> {
      console_writeln("Error: " <> error_to_string(err, env.opts.verbose))
      case env.opts.verbose {
        True -> {
          dump_env("repl", env)
          dbgout2("last funcall:", process_dict_get(env.pdic, "last_funcall"))
          dbgout2("last expr:", process_dict_get(env.pdic, "last_expr"))
        }
        False -> {
          False
        }
      }
      repl(env, prompt)
    }
  }
}

pub fn initialize() {
  gleam_bridge.init_gleam_bridge()
}

pub fn main() {
  initialize()

  //test()
  let pdic: PDic = unique_pdic()
  let env = make_new_l4u_core_env(pdic, [], [])
  //let env = make_new_l4u_core_env(unsafe_corece(UNDEFINED), [], [])
  repl(env, "stepA> ")
}

// ----------------------------------------------------------------------------
// # test
// ----------------------------------------------------------------------------

fn dump_list(list: List(String), env: Env) {
  list.each(list, fn(e) { dbgout1(e) })
}
