import gleam/dynamic.{Dynamic}
import gleam/map.{Map}
import l4u/sys_bridge.{unsafe_corece}

@external(erlang, "persistent_term", "get")
pub fn keys() -> List(String)

@external(erlang, "persistent_term", "get")
pub fn get(a: String) -> any

@external(erlang, "persistent_term", "get")
pub fn get_int(a: String) -> Int

@external(erlang, "persistent_term", "get")
pub fn get_str(a: String) -> String

@external(erlang, "persistent_term", "put")
pub fn put(a: String, b: any) -> Nil

@external(erlang, "persistent_term", "put")
pub fn put_int(a: String, b: Int) -> Nil

@external(erlang, "persistent_term", "put")
pub fn put_str(a: String, b: String) -> Nil

@external(erlang, "persistent_term", "erase")
pub fn erase(a: String) -> Nil

pub fn get_map(key: String) -> Map(String, any) {
  let assert dic: Map(String, any) = get(key)
  dic
}

@external(erlang, "persistent_term", "get")
pub fn get_with_default(a: String, default_value: any) -> any

pub fn get_map_value(
  key: String,
  property_key: String,
  default_value: any,
) -> any {
  let assert dic: Map(String, any) = get_with_default(key, map.new())
  case map.get(dic, property_key) {
    Ok(value) -> value
    _ -> default_value
  }
}

pub fn set_map_value(
  key: String,
  property_key: String,
  property_value: Dynamic,
) -> Nil {
  let dic = get_with_default(key, map.new())
  let new_dict = map.insert(dic, property_key, property_value)
  put(key, new_dict)
}
