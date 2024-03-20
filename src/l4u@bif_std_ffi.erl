-module(l4u@bif_std_ffi).
-compile(export_all).
-import(l4u_ffi, [unsafe_corece/1, to_char_list/1, to_bin_string/1, to_l4u_string/1, to_symbol/1, l4u_to_native/1,native_to_l4u/1]).

json_format(Expr) ->
    NativeExpression = l4u_to_native(Expr),
    %io:format("NativeExpression: ~p~n", [NativeExpression]),
    JsonString = jsone:encode(NativeExpression,[native_utf8]),
    %io:format(": ~p~n", [NativeExpression]),
    to_bin_string(JsonString).

json_parse(Bin) ->
    JsonString = to_bin_string(Bin),
    NativeExpression = jsone:decode(JsonString),
    native_to_l4u(NativeExpression).