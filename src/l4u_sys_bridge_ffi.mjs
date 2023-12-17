//const readline = require('readline');
import readline from 'readline';
import "./l4u_sys_bridge.mjs";
//**how do I import * as $result from "gleam_stdlib/gleam/result.mjs";
//**X** import "./gleam_stdlib/gleam/result.mjs";
import "../gleam_stdlib/gleam/result.mjs";  // OKみたい・・・


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
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// readline.question を Promise でラップする関数
const questionAsync = (query) => {
  return new Promise((resolve) => {
    rl.question(query, (input) => {
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

export const escape_binary_string = (str) => {
  return escape_string(str);
}
export const unescape_binary_string = (str) => {
  return unescape_string(str);
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


let _dict = {};
export const process_dict_set = (key,val) => {
  //console.log("- process_dict_set(",key.valueOf(),": ",val,")");
  _dict[key] = val;
  return val;
}
export const process_dict_get = (key) => {
  let value = _dict[key];
  if( value === undefined ) {
    //return api.string_to_symbol("undefined");
    return api.UNDEFINED;
  }
  //console.log("- process_dict_get(",key.valueOf(),") => ",value);
  return value; 
}

export const tick_count = () => {
  console.log("tick_count:",Date.now());
  return Date.now();
}

let _uid2 = 0;
export const unique_int = () => {
  return _uid2++;
}

let _pid = 0;
export const new_process = (env) => {
  var pid = _pid++;
  return pid;
}

export const exec = (pid,fn) => {
  return fn();
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

