import mustache from "mustache";
import {list_to_array} from "./l4u_sys_bridge_ffi.mjs";

// plist to map
export function plist_to_map(plist) {
    let dict = {};
    for(let x of plist) {
        let key = x[0];
        let value = x[1];
        dict[key] = value;
    }
    return dict;
}

export function render(template, table) {
    //console.log("plist:", table)
    table = plist_to_map(table);
    //console.log("map:", table)
    return mustache.render(template, table);
}