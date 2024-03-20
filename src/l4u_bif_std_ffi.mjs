import {get_gleam_bridge,native_to_l4u} from "./l4u_sys_bridge_ffi.mjs";

let api = get_gleam_bridge();

export function native_to_json(jsvalue) {
    return JSON.stringify(jsvalue,null,2);
}

export function json_parse(json) {
    let jsvalue = JSON.parse(json);
    //console.log("jsvalue:",jsvalue);
    let l4u_expr = native_to_l4u(jsvalue);
    //console.log("l4u_expr:",l4u_expr); 
    return l4u_expr;
}

export function json_format(expr) {
    let native_js = api.l4u_to_native(expr);
    let str_json = JSON.stringify(native_js,null,2);
    return str_json;
}

export function to_native_js(expr) {
    let native_js = api.l4u_to_native(expr);
    return native_js;
}