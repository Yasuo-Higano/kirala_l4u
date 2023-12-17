import gleam/dynamic.{Dynamic}
@target(javascript)
import gleam/javascript/promise.{Promise}
import gleam/order.{Order}

pub type Pid

pub type Ref

pub type PDic

@external(erlang, "l4u_ffi", "l4u_to_native")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "l4u_to_native")
pub fn l4u_to_native(value: expr) -> any

@external(erlang, "l4u_ffi", "native_to_l4u")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "native_to_l4u")
pub fn native_to_l4u(value: Dynamic) -> any

@external(erlang, "l4u_ffi", "to_bin_string")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "to_bin_string")
pub fn to_string(x: any) -> String

@external(erlang, "l4u_ffi", "unsafe_corece")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "unsafe_corece")
pub fn unsafe_corece(value: a) -> b

// ----------------------------------------------------------------------------

@external(erlang, "l4u@sys_bridge_ffi", "unique_pdic")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "unique_pdic")
pub fn unique_pdic() -> PDic

@external(erlang, "l4u@sys_bridge_ffi", "aux_pdic")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "aux_pdic")
pub fn aux_pdic(pdic: PDic, id: String) -> PDic

@target(javascript)
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "set_gleam_bridge")
pub fn set_gleam_bridge(key: String, value: any) -> Nil

@target(erlang)
@external(erlang, "l4u@sys_bridge_ffi", "console_readline")
pub fn console_readline(prompt: String) -> String

@target(javascript)
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "console_readline")
pub fn console_readline(prompt: String) -> Promise(String)

@external(erlang, "l4u@sys_bridge_ffi", "console_writeln")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "console_writeln")
pub fn console_writeln(s: any) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "do_async")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "do_async")
pub fn do_async(f: fn() -> Nil) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "dbgout1")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "dbgout1")
pub fn dbgout1(a: a) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "dbgout2")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "dbgout2")
pub fn dbgout2(a: a, b: b) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "dbgout3")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "dbgout3")
pub fn dbgout3(a: a, b: b, c: c) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "dbgout4")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "dbgout4")
pub fn dbgout4(a: a, b: b, c: c, d: d) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "catch_ex")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "catch_ex")
pub fn catch_ex(try_fn: fn() -> any) -> Result(any, err)

@external(erlang, "l4u@sys_bridge_ffi", "throw_err")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "throw_err")
pub fn throw_err(s: String) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "throw_expr")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "throw_expr")
pub fn throw_expr(expr: expr) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "load_file")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "load_file")
pub fn load_file(filename: String) -> String

@external(erlang, "l4u@sys_bridge_ffi", "make_ref")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "make_ref")
pub fn make_ref(value: any) -> Ref

@external(erlang, "l4u@sys_bridge_ffi", "deref")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "deref")
pub fn deref(ref: Ref) -> any

@external(erlang, "l4u@sys_bridge_ffi", "reset_ref")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "reset_ref")
pub fn reset_ref(ref: Ref, value: any) -> any

@external(erlang, "l4u@sys_bridge_ffi", "internal_form")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "internal_form")
pub fn internal_form(value: any) -> String

@external(erlang, "l4u@sys_bridge_ffi", "external_form")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "external_form")
pub fn external_form(value: any) -> String

@external(erlang, "l4u@process", "new_process")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "new_process")
pub fn new_process(initializer: fn() -> env) -> Result(Pid, error)

@external(erlang, "l4u@process", "exec")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "exec")
pub fn exec(pid: Pid, f: fn(env) -> any) -> Result(any, error)

@external(erlang, "l4u@process", "exec_native")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "exec_native")
pub fn exec_native(pid: Pid, f: fn(env) -> any) -> Result(any, error)

@external(erlang, "l4u@sys_bridge_ffi", "get_command_line_args")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "get_command_line_args")
pub fn get_command_line_args() -> List(String)

@external(erlang, "l4u@sys_bridge_ffi", "escape_binary_string")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "escape_binary_string")
pub fn escape_binary_string(str: String) -> String

@external(erlang, "l4u@sys_bridge_ffi", "unescape_binary_string")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "unescape_binary_string")
pub fn unescape_binary_string(str: String) -> String

@external(erlang, "l4u@sys_bridge_ffi", "process_dict_set")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "process_dict_set")
pub fn process_dict_set(pdic: PDic, key: String, value: any) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "process_dict_get")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "process_dict_get")
pub fn process_dict_get(pdic: PDic, key: String) -> any

@external(erlang, "l4u@sys_bridge_ffi", "process_dict_erase")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "process_dict_erase")
pub fn process_dict_erase(pdic: PDic, key: String) -> any

@external(erlang, "l4u@sys_bridge_ffi", "process_dict_keys")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "process_dict_keys")
pub fn process_dict_keys(pdic: PDic) -> List(String)

@external(erlang, "l4u@sys_bridge_ffi", "tick_count")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "tick_count")
pub fn tick_count() -> Int

@external(erlang, "l4u@sys_bridge_ffi", "unique_int")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "unique_int")
pub fn unique_int() -> Int

@external(erlang, "l4u@sys_bridge_ffi", "unique_str")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "unique_str")
pub fn unique_str() -> String

@external(erlang, "l4u@sys_bridge_ffi", "compare_any")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "compare_any")
pub fn compare_any(x: x, y: y) -> Order

@external(erlang, "l4u@sys_bridge_ffi", "os_cmd")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "os_cmd")
pub fn os_cmd(cmdline: String) -> String

@external(erlang, "l4u@sys_bridge_ffi", "stringify")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "stringify")
pub fn stringify(x: any) -> String

@external(erlang, "l4u@sys_bridge_ffi", "error_to_string")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "error_to_string")
pub fn error_to_string(x: any, verbose: Bool) -> String

// ----------------------------------------------------------------------------
// # file system
// ----------------------------------------------------------------------------
@external(erlang, "l4u@sys_bridge_ffi", "file_exists")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "file_exists")
pub fn file_exists(file_path: String) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "dir_exists")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "dir_exists")
pub fn dir_exists(dir_path: String) -> Bool

@external(erlang, "l4u@sys_bridge_ffi", "get_cwd")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "get_cwd")
pub fn get_cwd() -> String

@external(erlang, "l4u@sys_bridge_ffi", "set_cwd")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "set_cwd")
pub fn set_cwd(dir_path: String) -> Nil

@external(erlang, "l4u@sys_bridge_ffi", "abspath")
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "abspath")
pub fn abspath(path: String) -> String

// ----------------------------------------------------------------------------
// # javascript only
// ----------------------------------------------------------------------------

@target(javascript)
@external(javascript, "./l4u_sys_bridge_ffi.mjs", "tco_loop")
pub fn tco_loop(f: tco_function, initial_param: initial_param) -> any

@target(erlang)
pub fn tco_loop(f: tco_function, initial_param: initial_param) -> any {
  todo
}
