//import {toList as toList_} from "../prelude.mjs";
import {toList} from "../prelude.mjs";
//export {toList} from "../prelude.mjs";
import {get_gleam_bridge} from "./l4u_sys_bridge_ffi.mjs";

let api = get_gleam_bridge();
//

export function js_bifs() {
    return api.array_to_list([]);
};

export function js_array_to_gleam_list(arr) {
    return toList(arr);
}