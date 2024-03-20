
const _persistent_term = {};

export function keys() {
    return Object.keys(_persistent_term);
}

export function get(key) {
    return _persistent_term[key];
}

export function put(key, value) {
    _persistent_term[key] = value;
}

export function erase(key) {
    delete _persistent_term[key];
}

export function get_with_default(key,value) {
    if( _persistent_term[key] === undefined ) {
        return value;
    }
    return _persistent_term[key];
}