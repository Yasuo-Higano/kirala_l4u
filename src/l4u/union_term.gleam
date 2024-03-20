import gleam/dynamic.{type Dynamic}
import gleam/dict.{type Dict}
import l4u/l4u_type.{unsafe_corece}

@external(erlang, "persistent_term", "keys")
@external(javascript, "../l4u_union_term_js.mjs", "keys")
pub fn keys() -> List(String)

@external(erlang, "persistent_term", "get")
@external(javascript, "../l4u_union_term_js.mjs", "get")
pub fn get(key: String, default_value: any) -> any

@external(erlang, "persistent_term", "get")
@external(javascript, "../l4u_union_term_js.mjs", "get")
pub fn get_int(key: String, default_value: Int) -> Int

@external(erlang, "persistent_term", "get")
@external(javascript, "../l4u_union_term_js.mjs", "get")
pub fn get_str(key: String, default_value: String) -> String

@external(erlang, "persistent_term", "put")
@external(javascript, "../l4u_union_term_js.mjs", "put")
pub fn put(key: String, value: any) -> Nil

@external(erlang, "persistent_term", "put")
@external(javascript, "../l4u_union_term_js.mjs", "put")
pub fn put_int(key: String, value: Int) -> Nil

@external(erlang, "persistent_term", "put")
@external(javascript, "../l4u_union_term_js.mjs", "put")
pub fn put_str(key: String, value: String) -> Nil

@external(erlang, "persistent_term", "erase")
@external(javascript, "../l4u_union_term_js.mjs", "erase")
pub fn erase(key: String) -> Nil

pub fn get_map(key: String) -> Dict(String, any) {
  let assert dic: Dict(String, any) = get(key, dict.new())
  dic
}

@external(erlang, "persistent_term", "get")
@external(javascript, "../l4u_union_term_js.mjs", "get_with_default")
pub fn get_with_default(a: String, default_value: any) -> any

@external(erlang, "persistent_term", "get")
@external(javascript, "../l4u_union_term_js.mjs", "get_with_default")
pub fn nt_get_with_default(a: key, default_value: any) -> any

@external(erlang, "persistent_term", "put")
@external(javascript, "../l4u_union_term_js.mjs", "put")
pub fn nt_put(key: key, value: any) -> Nil

pub fn get_map_value(
  key: String,
  property_key: String,
  default_value: any,
) -> any {
  let assert dic: Dict(String, any) = get_with_default(key, dict.new())
  case dict.get(dic, property_key) {
    Ok(value) -> value
    _ -> default_value
  }
}

pub fn set_map_value(
  key: String,
  property_key: String,
  property_value: Dynamic,
) -> Nil {
  let dic = get_with_default(key, dict.new())
  let new_dict = dict.insert(dic, property_key, property_value)
  put(key, new_dict)
}
