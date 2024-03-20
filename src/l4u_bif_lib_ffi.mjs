import {get_gleam_bridge} from "./l4u_sys_bridge_ffi.mjs";

let api = get_gleam_bridge();
//

export function invoke_native_function(ntfun,args) {
    Reflect.apply(ntfun, undefined, args);
};
