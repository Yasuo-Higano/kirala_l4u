import {get_gleam_bridge} from "./l4u_sys_bridge_ffi.mjs";

let api = get_gleam_bridge();
//

export function js_bifs() {
    return api.array_to_list([]);
};
