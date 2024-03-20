import readline from 'readline';
//const readline = require('readline');
//import "./l4u_sys_bridge.mjs";
//**how do I import * as $result from "gleam_stdlib/gleam/result.mjs";
//**X** import "./gleam_stdlib/gleam/result.mjs";
import "../gleam_stdlib/gleam/result.mjs";  // OKみたい・・・
import 'path';
import {load as load_resource} from './l4u_resources.mjs';


let _gleam_bridge = {};
let api = _gleam_bridge;
export function set_gleam_bridge(key,value) {
  console.log("- set_gleam_bridge:",key,value);
  _gleam_bridge[key] = value;
}

export function get_gleam_bridge() {
  return _gleam_bridge;
}


// readline インターフェイスの作成
let _readline = null;
function get_readline() {
  if( _readline === null ) {
    _readline = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }
  return _readline;
};

// readline.question を Promise でラップする関数
const questionAsync = (query) => {
  return new Promise((resolve) => {
    get_readline().question(query, (input) => {
      resolve(input);
    });
  });
};

export const console_readline = async (prompt) => {
  let input = await questionAsync(prompt);
  return input;
}

// どんな値でも文字列に変換する関数
const toString = (value) => {
    if (value === null) {
        return "null";
    } else if (value === undefined) {
        return "undefined";
    } else {
        return String(value);
    }
}

let buf = "";
export const console_write = (value) => {
  let s = toString(value);
  console.log("## console_write:",s);
  buf += s;
  return s;
}
export const console_writeln = (value) => {
  let s = buf + toString(value);
  console.log(s);
  buf = "";
  return s;
}

export const do_async = (f) => {
    f().then(() => {console.log("then")});
}

export const dbgout1 = (a) => {
  console.log(a);
}
export const dbgout2 = (a,b) => {
  console.log(a,b);
}
export const dbgout3 = (a,b,c) => {
  console.log(a,b,c);
}
export const dbgout4 = (a,b,c,d) => {
  console.log(a,b,c,d);
}

export const throw_err = (msg) => {
  throw new Error("#l4u:"+msg);
}

export const throw_expr = (msg) => {
  throw new Error("#l4u:"+msg);
}

//const fs = require('fs');
import fs from 'fs';

export const load_file = (filename) => {
    return load_file_(filename,["","scripts/","scripts/lib/","scripts/tests/"]);
}

function load_file_(filename,paths) {
  for(let path of paths) {
    let fullpath = path+filename;
    if( fs.existsSync(fullpath) ) {
      console.log("## load_file:",fullpath);
      let text = fs.readFileSync(fullpath);
      // ここで明示的に文字列に変換
      return ""+text;
    }
  }
 
  //
  for(let path of paths) {
    let fullpath = path+filename;
    console.log("## load_file:",fullpath);
    let text = load_resource(fullpath);
    if( text !== undefined ) {
      return ""+text;
    }
  }

  return "";
}


let _uid = 0;
export const new_uid = () => {
  return `ref<${_uid++}>`;
}

export const make_ref = (value) => {
  let uid = new_uid();
  return {uid,value};
}

export const deref = (ref) => {
  return ref.value;
}

export const reset_ref = (ref,value) => {
  let result = ref.value;
  ref.value = value;
  return result;
}

export const get_command_line_args = () => {
  return _gleam_bridge.array_to_list(process.argv);h
}

//export const escape_binary_string = (str) => {
//  console.log("escape_binary_string:",str);
//  let native_str = api.l4u_to_native(str);
//  console.log("native_str:",native_str);
//  let escaped_str = escape_string(native_str);
//  console.log("escaped_str:",escaped_str);
//  let str_expr = api.string( escaped_str );
//  console.log("str_expr:",str_expr);
//  return str_expr;
//}
//export const unescape_binary_string = (str) => {
//  return api.string( unescape_string(api.l4u_to_native(str)) );
//}

export const escape_binary_string = (str) => {
  return escape_string(""+str);
}
export const unescape_binary_string = (str) => {
  return unescape_string(""+str);
}

export const escape_string = (str) => {
  return str.replace(/\\/g, '\\\\')
             .replace(/\r/g, '\\r')
             .replace(/\n/g, '\\n')
             .replace(/\t/g, '\\t')
             .replace(/"/g, '\\"');
}

export const unescape_string = (str) => {
  return str.replace(/\\\\/g, '\\')
             .replace(/\\r/g, '\r')
             .replace(/\\n/g, '\n')
             .replace(/\\t/g, '\t')
             .replace(/\\"/g, '"');
}


export const erl_sym = (sym) => {
  return Symbol(sym);
}


export const tick_count = () => {
  //console.log("tick_count:",Date.now());
  return Date.now();
}

let _uid2 = 0;
export const unique_int = () => {
  return _uid2++;
}
export const unique_str = () => {
  return `#${unique_int()}#`;
}

export const unique_pdic = () => {
  return {};
}
export const aux_pdic = (PDIC,ID) => {
  PDIC[ID] = {};
  return PDIC[ID];
}

let _processes = {};
let _pid = 0;
export const new_process = (initializer) => {
  let env = initializer();

  //console.log("######## new_process:",env);

  var pid = ["PID",_pid++];
  _processes[pid] = env;
  return api.Ok(pid);
  //return api.Ok(env);
}

// WithEnv(Expr,Env) の型を受け取り、Ok(Expr)を返す
export const exec = (pid,f) => {
  //console.log("######## exec:",pid,f);
  let env = process_get_env(pid);
  let res = f(env);
  //console.log("######## exec: res=",res);
  // env = res[1];
  return api.Ok( res[0] );
}
export const exec_native = (pid,fn) => {
  return fn();
}

export const process_dict_set = (pdic,key,val) => {
  //console.log("- process_dict_set(",key.valueOf(),": ",val,")");
  pdic[key] = val;
  return val;
}
export const process_dict_get = (pdic,key) => {
  let value = pdic[key];
  if( value === undefined ) {
    //return api.string_to_symbol("undefined");
    return api.UNDEFINED;
  }
  //console.log("- process_dict_get(",key.valueOf(),") => ",value);
  return value; 
}
export const process_dict_erase = (pdic,key) => {
  delete pdic[key];
}
export const process_dict_keys = (pdic) => {
  let keys = Object.keys(pdic);
  return api.array_to_list(keys);
}

export const process_get_env = (pid) => {
  return _processes[pid];
}

export const catch_ex = (fn) => {
  try {
    //return new Ok( fn() );
    return _gleam_bridge.return_ok( fn() );
  }
  catch(e) {
    //return e;
    return _gleam_bridge.return_error( e );
  }
}

export const throw_ex = (e) => {
  throw e;
}

export const internal_form = (x) => {
  console.log("internal_form:",x);
  return ""+x;
}
export const external_form = (x) => {
  //console.log("external_form:",x);
  return ""+x;
}

export const to_bin_string = (x) => {
  return ""+x;
}


let tco_nest_level = 0;
export const tco_loop = (f,initial_param) => {
  //tco_nest_level++;
  //console.log("+ tco_loop:",tco_nest_level);

  let param = initial_param;
  while(true) {
    let result = f(param);
    if( result.isOk() ) {
      //tco_nest_level--;
      //console.log("- tco_loop:",tco_nest_level);
      return result[0];
    }
    else {
      param = result[0];
    }
  }
}

export function list_to_array(xs) {
  let ys = [];
  for(let x of xs) {
    ys.push(x);
  }
  return ys;
}



export function to_native_dictionary(xs) {
  //console.log("to_native_dictionary:",xs);
  let dict = {};

  xs = list_to_array(xs);
  for(let i=0; i<xs.length; i+=2) {
    let key = xs[i];
    let value = xs[i+1];
    //console.log("to_native_dictionary item:",key,value);
    dict[key] = value;
  }
  return dict;
}

export function native_undefined() {
  return undefined;
}
export function native_nil() {
  return null;
}
export function native_true() {
  return true;
}
export function native_false() {
  return false;
}

async function getFunction(moduleName, functionName) {
  const module = await import(moduleName);
  return module[functionName];
}


export async function erl_ref_native_fun(module_name, function_name) {
  return await getFunction(module_name, function_name); 
}

export function abspath(r_path) {
  const absolutePath = path.resolve(r_path);
  return absolutePath;
}

export function compare_any_(x, y) {
  if( x == y ) {
    return 0;
  }
  else if( x < y ) {
    return -1;
  }
  else {
    return 1;
  }
}

export function file_exists(path) {
  return fs.existsSync(path);
}

export function dir_exists(path) {
  return fs.existsSync(path);
}

export function error_to_string(error) {
  return error.toString();
}

export function get_cwd() {
  return process.cwd();
}

export function unsafe_corece(value) {
  return value;
}

export function native_to_l4u(value) {
  if( value === undefined ) {
    return api.UNDEFINED;
  }
  else if( value === null ) {
    return api.NIL;
  }
  else if( value === true ) {
    return api.TRUE;
  }
  else if( value === false ) {
    return api.FALSE;
  }
  else if( typeof value === "string" ) {
    return api.string(value);
  }
  else if( typeof value === "number" ) {
    if( Math.floor(value) === value ) {
      return api.int(value);
    }
    else {
      return api.float(value);
    }
  }
  else if( Array.isArray(value) ) {
    return api.array_to_list(value);
  }
  else if( typeof value === "object" ) {
    let keys = Object.keys(value);
    let plist = [];
    for(let key of keys) {
      plist.push(key);
      plist.push(value[key]);
    }
    return api.dict(api.array_to_list(plist));
  }
  else {
    return value;
  }
}

export function os_cmd(cmd) {
  return require('child_process').execSync(cmd).toString();
}
export function set_cwd(path) {
  process.chdir(path);
}
export function stringify(value) {
  return ""+value;
}

export function erl_fn_apply(fn,args) {
  return fn(...args);
}

export function erl_get_module_functions(module_name) {
  return require(module_name);
}