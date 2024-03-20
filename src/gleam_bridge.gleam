import gleam/list
@target(javascript)
import gleam/javascript/array
import l4u/l4u_type.{
  FALSE, NIL, SYMBOL, TRUE, UNDEFINED, box_l4u_custom_type,
  box_l4u_custom_type_def, box_l4u_dict, box_l4u_float, box_l4u_int,
  box_l4u_keyword, box_l4u_list, box_l4u_native_function, box_l4u_native_value,
  box_l4u_ok, box_l4u_string, box_l4u_symbol, box_l4u_vector, unbox_l4u,
}
@target(javascript)
import l4u/sys_bridge.{set_gleam_bridge}

pub fn return_ok(value: any) -> Result(any, error) {
  Ok(value)
}

pub fn return_error(value: error) -> Result(any, error) {
  Error(value)
}

@target(javascript)
pub fn init_gleam_bridge() {
  let bridge = [#("return_ok", return_ok), #("return_error", return_error)]

  list.each(bridge, fn(i) {
    let #(key, value) = i
    set_gleam_bridge(key, value)
  })

  //
  set_gleam_bridge("array_to_list", array.to_list)
  set_gleam_bridge("string_to_symbol", SYMBOL)
  set_gleam_bridge("UNDEFINED", UNDEFINED)
  set_gleam_bridge("TRUE", TRUE)
  set_gleam_bridge("FALSE", FALSE)
  set_gleam_bridge("NIL", NIL)

  //
  set_gleam_bridge("int", box_l4u_int)
  set_gleam_bridge("float", box_l4u_float)
  set_gleam_bridge("string", box_l4u_string)
  set_gleam_bridge("symbol", box_l4u_symbol)
  set_gleam_bridge("keyword", box_l4u_keyword)
  set_gleam_bridge("list", box_l4u_list)
  set_gleam_bridge("vector", box_l4u_vector)
  set_gleam_bridge("dict", box_l4u_dict)
  set_gleam_bridge("native_value", box_l4u_native_value)
  set_gleam_bridge("native_function", box_l4u_native_function)
  set_gleam_bridge("custom_type", box_l4u_custom_type)
  set_gleam_bridge("custom_type_def", box_l4u_custom_type_def)
  set_gleam_bridge("Ok", box_l4u_ok)

  set_gleam_bridge("l4u_to_native", unbox_l4u)

  True
}

@target(erlang)
pub fn init_gleam_bridge() {
  True
}
