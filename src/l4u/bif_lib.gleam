import gleam/io
import gleam/list
import gleam/dict
import gleam/string
import gleam/regex
import gleam/result
import gleam/int
import gleam/float
import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/order
import l4u/sys_bridge.{
  type Pid, catch_ex, console_readline, console_writeln, dbgout1, dbgout2,
  dbgout3, deref, do_async, erl_sym, internal_form, l4u_to_native, load_file,
  make_ref, native_to_l4u, os_cmd, process_dict_get, process_dict_keys,
  process_dict_set, reset_ref, throw_err, throw_expr,
}
@target(javascript)
import gleam/javascript/promise
import l4u/l4u_core.{
  description, dump_env, env_set_global, env_set_local, eval, inspect,
  main as do_repl, make_new_l4u_core_env, print, pstr, rep, repl,
  trace_set_last_funcall, uneval,
}
import l4u/l4u_type.{
  type Env, type Expr, BIF, BISPFORM, KEYWORD, LIST, NIL, NativeFunction,
  NativeValue, STRING, SYMBOL, UNDEFINED, VECTOR, WithEnv, native_false,
  native_nil, native_true, native_undefined, to_native_dictionary, unsafe_corece,
}
import l4u/l4u_core as l4u
import l4u/union_term

// ----------------------------------------------------------------------------
// # library
// ----------------------------------------------------------------------------

fn bif_pr_str(exprs: List(Expr), env: Env) -> Expr {
  let str =
    list.map(exprs, print)
    |> string.join(" ")
  WithEnv(STRING(str), env)
}

fn bif_seq(exprs: List(Expr), env: Env) -> Expr {
  let assert [x] = exprs
  let seq = case x {
    NIL -> NIL
    STRING("") -> NIL
    STRING(s) -> {
      let graphemes =
        string.to_graphemes(s)
        |> list.map(STRING)
      LIST(graphemes)
    }
    LIST(xs) | VECTOR(xs) -> {
      case xs {
        [] -> NIL
        _ -> LIST(xs)
      }
    }
    _ -> {
      throw_err("seq: wrong number of arguments")
      UNDEFINED
    }
  }
  WithEnv(seq, env)
}

fn bif_os_cmd(exprs: List(Expr), env: Env) -> Expr {
  let assert [STRING(cmd)] = exprs
  let res_str = os_cmd(cmd)
  WithEnv(STRING(res_str), env)
}

// ----------------------------------------------------------------------------
// # native functions
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "l4u@sys_bridge_ffi", "erl_get_module_info")
fn erl_get_module_info(module_name: String) -> Dynamic

pub fn erlang_module_of(exprs: List(Expr)) -> String {
  let module = case exprs {
    [STRING(module)] | [SYMBOL(module)] | [KEYWORD(module)] -> module
    [LIST(moddirs)] | [VECTOR(moddirs)] -> moddir_to_modulename(moddirs)
    _ -> {
      throw_err("native-module-info: wrong number of arguments")
      "err"
    }
  }
  module
}

@target(erlang)
fn bif_native_module_info(exprs: List(Expr), env: Env) -> Expr {
  let module = erlang_module_of(exprs)
  let module_info = erl_get_module_info(module)

  WithEnv(NativeValue("module_info", module_info), env)
}

@target(javascript)
fn bif_native_module_info(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(
    NativeValue("module_info", dynamic.from("module_info is unsupported")),
    env,
  )
}

// ----------------------------------------------------------------------------

@target(erlang)
@external(erlang, "l4u@sys_bridge_ffi", "erl_get_nodes")
fn erl_get_nodes() -> Expr

@target(erlang)
fn bif_native_nodes(exprs: List(Expr), env: Env) -> Expr {
  let nodes = erl_get_nodes()

  WithEnv(nodes, env)
}

@target(javascript)
fn bif_native_nodes(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(UNDEFINED, env)
}

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "l4u@sys_bridge_ffi", "erl_get_processes")
fn erl_get_processes() -> Expr

@target(erlang)
fn bif_native_processes(exprs: List(Expr), env: Env) -> Expr {
  let processes = erl_get_processes()
  WithEnv(processes, env)
}

@target(javascript)
fn bif_native_processes(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(UNDEFINED, env)
}

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "erlang", "self")
fn erl_self() -> Pid

@target(erlang)
fn bif_erl_self(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(NativeValue("pid", unsafe_corece(erl_self())), env)
}

@target(javascript)
fn bif_erl_self(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(UNDEFINED, env)
}

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "erlang", "send")
fn erl_send() -> Pid

// (send Pid Channel Message)
fn bif_erl_send(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(UNDEFINED, env)
}

// ----------------------------------------------------------------------------
@target(erlang)
@external(erlang, "erlang", "receive")
fn erl_receive() -> Pid

// (receive-from Pid Channel Message)
fn bif_erl_receive_from(exprs: List(Expr), env: Env) -> Expr {
  WithEnv(UNDEFINED, env)
}

// ----------------------------------------------------------------------------

@external(erlang, "l4u@sys_bridge_ffi", "erl_ref_native_fun")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "erl_ref_native_fun")
fn erl_ref_native_fun(module: String, function_name: String) -> Dynamic

@external(erlang, "l4u@sys_bridge_ffi", "erl_get_module_functions")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "erl_get_module_functions")
fn erl_get_module_functions(module: String) -> List(#(String, Int))

pub fn moddir_to_modulename(moddir: List(Expr)) -> String {
  string.join(list.map(moddir, pstr), "@")
}

// (import-native-module [Module1 Module2 ...] [Prefix])
// (import-native-module :math) -> import all functions from math, fabs, log2, etc...
// (import-native-module [:math] "m") -> import all functions from math, with prefix "m", m:fabs, m:log2, etc...
fn bif_import_native_module(exprs: List(Expr), env: Env) -> Expr {
  //dbgout2("bif_import_native_module", exprs)

  let exprs = case exprs {
    [moddir] -> [moddir, STRING(""), LIST([])]
    [moddir, prefix] -> [moddir, prefix, LIST([])]
    [moddir, prefix, options] -> [moddir, prefix, options]
    unhandable -> {
      throw_err("import-native-module: wrong number of arguments")
      []
    }
  }

  let imported_functions = case exprs {
    [moddir, prefix, options] -> {
      //let moddir = case moddir {
      //  LIST(moddir) -> LIST(moddir)
      //  _ -> LIST([STRING(pstr(moddir))])
      //}

      let assert LIST(moddir) = uneval(moddir)
      let assert LIST(options) = uneval(options)
      //dbgout2("moddir:", moddir)
      let prefix = pstr(prefix)
      //dbgout2("prefix:", prefix)
      let modname = moddir_to_modulename(moddir)
      //dbgout2("modname:", modname)
      let functions = erl_get_module_functions(modname)
      //dbgout2("functions:", functions)

      let underscore_to_hyphen =
        list.contains(options, KEYWORD("underscore-to-hyphen"))

      let delimiter = ":"

      list.map(functions, fn(fnname_and_arity) {
        let assert #(fnname, arity) = fnname_and_arity
        //dbgout3("fnname:", fnname, arity)
        let alias_name = case prefix {
          "" -> fnname
          _ -> string.join([prefix, fnname], delimiter)
        }

        let fnname = case underscore_to_hyphen {
          True -> string.replace(fnname, "_", "-")
          _ -> fnname
        }

        process_dict_set(
          env.pdic,
          alias_name,
          NativeFunction(
            alias_name,
            unsafe_corece(erl_ref_native_fun(modname, fnname)),
          ),
        )
        STRING(alias_name)
      })
    }
    _ -> {
      throw_err("import-native-module: wrong number of arguments")
      []
    }
  }
  WithEnv(LIST(imported_functions), env)
}

// (import-native-function [Module1 Module2 ...] FunctionName [Alias])
fn bif_import_native_function(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [moddir, fnname, alias] -> {
      let assert LIST(moddir) = uneval(moddir)
      let fnname = pstr(fnname)
      let alias_name = pstr(alias)
      let modname = string.join(list.map(moddir, pstr), "@")
      process_dict_set(
        env.pdic,
        alias_name,
        NativeFunction(
          fnname,
          //unsafe_corece(#(erl_sym(modname), erl_sym(fnname))),
          unsafe_corece(erl_ref_native_fun(modname, fnname)),
        ),
      )
    }
    [moddir, fnname] -> {
      let assert LIST(moddir) = uneval(moddir)
      let fnname = pstr(fnname)
      let alias_name = fnname
      let modname = string.join(list.map(moddir, pstr), "@")
      process_dict_set(
        env.pdic,
        alias_name,
        NativeFunction(
          alias_name,
          //unsafe_corece(#(erl_sym(modname), erl_sym(fnname))),
          unsafe_corece(erl_ref_native_fun(modname, fnname)),
        ),
      )
    }
    unhandable -> {
      throw_err("import-native-function: wrong number of arguments")
    }
  }
  NIL
}

fn bif_import_native_functions(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [moddir, fnnames] -> {
      let assert LIST(moddir) = uneval(moddir)
      let assert LIST(fnnames) = uneval(fnnames)
      let modname = string.join(list.map(moddir, pstr), "@")
      list.each(fnnames, fn(fnname) {
        let fnname = pstr(fnname)
        let alias_name = fnname
        process_dict_set(
          env.pdic,
          alias_name,
          NativeFunction(
            alias_name,
            //unsafe_corece(#(erl_sym(modname), erl_sym(fnname))),
            unsafe_corece(erl_ref_native_fun(modname, fnname)),
          ),
        )
      })
    }
    _ -> {
      throw_err("import-native-functions: wrong number of arguments")
    }
  }
  NIL
}

// (native-function [:module] ])
fn bif_native_function(exprs: List(Expr), env: Env) -> Expr {
  case exprs {
    [moddir, fnname] -> {
      let modname = case uneval(moddir) {
        VECTOR(moddir) | LIST(moddir) -> moddir_to_modulename(moddir)
        expr -> pstr(expr)
      }
      let fnname = pstr(uneval(fnname))
      let alias_name = fnname
      NativeFunction(
        alias_name,
        //unsafe_corece(#(erl_sym(modname), erl_sym(fnname))),
        unsafe_corece(erl_ref_native_fun(modname, fnname)),
      )
    }
    _ -> {
      throw_err("native-function: wrong number of arguments")
      UNDEFINED
    }
  }
}

//fn erl_apply(module: module, fnname: fnname, args: args) -> Dynamic
@external(erlang, "l4u@sys_bridge_ffi", "erl_fn_apply")
@external(javascript, "../l4u_sys_bridge_ffi.mjs", "erl_fn_apply")
fn erl_fn_apply(fun: fun_def, args: args) -> Dynamic

// (invoke-native-function FunctionName [Arg1 Arg2 ...])
fn bif_invoke_native_function(exprs: List(Expr), env: Env) -> Expr {
  let assert [native_fun, args] = exprs
  let assert LIST(args) = uneval(args)

  let rexpr = invoke_native_function(native_fun, args)
  //dbgout2("# invoke native function returns rexpr:", rexpr)
  WithEnv(rexpr, env)
}

// この関数は戻り値をExprにして返すだけなので注意！
// evalから使う場合は、WithEnvで包んで返すこと！
pub fn invoke_native_function(native_fun: Expr, args: List(Expr)) -> Expr {
  //dbgout3("# invoke_native_function", native_fun, args)
  let assert NativeFunction(_name, native_fundef) = uneval(native_fun)
  let #(modpath, fnname) = unsafe_corece(native_fundef)
  //dbgout3("# invoke_native_function modpath, fnname:", modpath, fnname)

  let native_args = list.map(args, l4u_to_native)
  //dbgout2("# invoke_native_function native_args:", native_args)
  let erl_result = erl_fn_apply(native_fundef, native_args)
  //dbgout2("# invoke_native_function erl_result:", erl_result)
  let cvl4u = native_to_l4u(erl_result)
  //dbgout1("# native_to_l4u cvl4u done.")
  //dbgout2("# invoke_native_function cvl4u:", cvl4u)
  cvl4u
}

fn bif_shared_put(exprs: List(Expr), env: Env) -> Expr {
  let assert [key, value] = exprs
  union_term.put(pstr(key), value)
  WithEnv(value, env)
}

fn bif_shared_get(exprs: List(Expr), env: Env) -> Expr {
  let assert [key, default_value] = exprs
  let rval = union_term.get(pstr(key), default_value)
  WithEnv(rval, env)
}

// ----------------------------------------------------------------------------
// # bif table
// ----------------------------------------------------------------------------

pub fn bif_lib_def() -> List(#(String, Expr)) {
  let bif = fn(name, f) { #(name, BIF(description(name), f)) }
  let bsf = fn(name, f) { #(name, BISPFORM(description(name), f)) }

  [
    //bif("pr-str", bif_pr_str),
    bif("seq", bif_seq),
    // native functions ----------------------------------------
    bif("self", bif_erl_self),
    bif("send", bif_erl_send),
    bif("receive-from", bif_erl_receive_from),
    bif("import-native-module", bif_import_native_module),
    bif("import-native-function", bif_import_native_function),
    bif("import-native-functions", bif_import_native_functions),
    bif("native-function", bif_native_function),
    bif("invoke-native-function", bif_invoke_native_function),
    bif("os-cmd", bif_os_cmd),
    bif("native-module-info", bif_native_module_info),
    bif("native-nodes", bif_native_nodes),
    bif("native-processes", bif_native_processes),
    //
    bif("shared-put", bif_shared_put),
    bif("shared-get", bif_shared_get),
  ]
}
