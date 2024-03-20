
export function start() {

}

export function epoch() {
    return Date.now();
}

export function datetime_format(epoch, format) {
    return new Date(epoch).toLocaleString();
}

export function datetime_parse(str, format) {
    return Date.parse(str);
}

