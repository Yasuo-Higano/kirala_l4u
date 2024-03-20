-module(l4u_ffi).
-compile(export_all).

unsafe_corece(X) -> X.

to_char_list({'string',X}) -> binary_to_list(X);
to_char_list(X) when is_list(X) -> X;
to_char_list(X) when is_binary(X) -> binary_to_list(X).

to_bin_string(X) when is_list(X) -> list_to_binary(X);
to_bin_string(X) when is_binary(X) -> X;
to_bin_string(X) -> bfmt("~p", [X]).

to_symbol({string,X}) -> to_symbol(X);
to_symbol({symbol,X}) -> to_symbol(X);
to_symbol({keyword,X}) -> to_symbol(X);
to_symbol(X) when is_list(X) -> list_to_atom(X);
to_symbol(X) when is_binary(X) -> binary_to_atom(X);
to_symbol(X) when is_atom(X) -> X.

bfmt(Fmt,Args) ->
  list_to_binary(io_lib:format(Fmt,Args)).

to_l4u_string({int,X}) -> {'string',bfmt("~p", [X])};
to_l4u_string({symbol,X}) -> {'string',X};
to_l4u_string(X) when is_list(X) -> {'string',list_to_binary(X)};
to_l4u_string(X) when is_binary(X) -> {'string',X}.

l4u_to_native(true) -> true;
l4u_to_native(false) -> false;
l4u_to_native(undefined) -> undefined;
l4u_to_native(null) -> null;
l4u_to_native({vector,Value}) ->
    list_to_tuple( lists:map( fun(X) -> l4u_to_native(X) end, Value ) );
l4u_to_native({list,Value}) ->
    lists:map( fun(X) -> l4u_to_native(X) end, Value );
l4u_to_native({dict,Value}) ->
    NativeValues = lists:map( fun(X) -> l4u_to_native(X) end, Value ),
    l4u_alist_to_native(NativeValues,maps:new());
l4u_to_native({keyword,Value}) ->
    binary_to_atom(Value,utf8);
l4u_to_native({symbol,Value}) ->
    binary_to_atom(Value,utf8);
l4u_to_native({int,Value}) ->
    Value;
l4u_to_native({float,Value}) ->
    Value;
l4u_to_native({string,Value}) ->
    Value;
l4u_to_native({native_value,Name,Value}) ->
    Value;
l4u_to_native(Value) ->
    %io:format("l4u_to_native: ~p~n", [Value]),
    Value.


native_to_l4u({ok, Value}) ->
    {native_value,<<"ok">>,Value};
native_to_l4u({error, Value}) ->
    {native_value,<<"error">>,Value};

native_to_l4u({Type, Value}) when is_atom(Type) ->
    %io:format("native_to_l4u: ~p ~p~n", [Type,Value]),
    {Type,Value};

native_to_l4u(true) -> true;
native_to_l4u(false) -> false;
native_to_l4u(undefined) -> undefined;
native_to_l4u(null) -> nil;
native_to_l4u(nil) -> nil;
native_to_l4u(Value) when is_tuple(Value) ->
    {vector,lists:map( fun(X) -> native_to_l4u(X) end, Value ) };
native_to_l4u(Value) when is_list(Value) ->
    {list,lists:map( fun(X) -> native_to_l4u(X) end, Value ) };
    %{vector,lists:map( fun(X) -> native_to_l4u(X) end, Value ) };
native_to_l4u(Value) when is_map(Value) ->
    {dict,
        lists:flatten(
            lists:map(
                fun({K,V}) ->
                    [native_to_l4u(K),native_to_l4u(V) ]
                end,
                Value
            ))};
native_to_l4u(Value) when is_atom(Value) ->
    {keyword,atom_to_binary(Value)};
native_to_l4u(Value) when is_integer(Value) ->
    {int,Value};
native_to_l4u(Value) when is_float(Value) ->
    {float,Value};
native_to_l4u(Value) when is_binary(Value) ->
    {string,Value};

%native_to_l4u(Value) ->
%    undefined.

native_to_l4u(Value) when is_reference(Value) ->
    %io:format("#debug: native_to_l4u: ref ~p~n", [Value]),
    {native_value,<<"ref">>,Value};
native_to_l4u(Value) ->
    %io:format("#debug: native_to_l4u: others ~p~n", [Value]),
    {native_value,<<"unknown">>,Value}.

%
l4u_alist_to_native([],Acc) ->
    Acc;
l4u_alist_to_native([Key,Value | Rest],Acc) ->
    l4u_alist_to_native(Rest,maps:put(Key,Value,Acc)).