-module(l4u@sys_bridge_ffi).
-compile(export_all).
-import(l4u_ffi, [unsafe_corece/1, to_char_list/1, to_bin_string/1, to_l4u_string/1, to_symbol/1, l4u_to_native/1,native_to_l4u/1]).
-define(L4U, l4u@stepa_ol4u).
%-define(SHOW, l4u@l4u_core:show/1).

% -----------------------------------------------------




% -----------------------------------------------------

console_readline_(Prompt) ->
    Result =
        case io:get_line(standard_io, Prompt) of
            eof ->
                % break out of the loop
                io:format("~n"),
                ok;
            {error, Reason} ->
                io:format("Error reading input: ~p~n", [Reason]),
                exit(ioerr);
            Line ->
                string:trim(Line,trailing)
        end.


console_readline_block(Prompt,Acc) ->
    Line = console_readline_(Prompt),
    Line2 = string:trim(Line,trailing),
    RLine = string:reverse(Line2),
    %io:format("<~p>~n", [RLine]),
    case RLine of
        % "\\"
        [92] ->
            string:join( lists:reverse(Acc), "\n" );
        [92|Rest] ->
            string:join( lists:reverse([string:reverse(Rest)|Acc]), "\n" );
        _ ->
            %io:format("Line2 = ~p~n", [Line2]),
            console_readline_block(Prompt,[Line2|Acc])
    end.

console_readline(Prompt) ->
    PromptLength = string:length(Prompt),
    NewPrompt = string:chars($\s,PromptLength),
    
    Line = console_readline_(Prompt),
    Result =
    case Line of
        % "\\"
        [92] ->
            console_readline_block(NewPrompt,[]);

        [92|Rest] ->
            console_readline_block(NewPrompt,[Rest]);
        _ ->
            Line
    end,

    to_bin_string(Result).


console_writeln(Val) ->
    io:format("~ts~n", [show(Val)]).

do_async(F) ->
    nil.

dbgout1(A) ->
    io:format("~ts\n", [show(A)]),
    false.

dbgout2(A,B) ->
    io:format("~ts ~ts\n", [show(A),show(B)]),
    false.

dbgout3(A,B,C) ->
    io:format("~ts ~ts ~ts\n", [show(A),show(B),show(C)]),
    false.

dbgout4(A,B,C,D) ->
    io:format("~ts ~ts ~ts ~ts\n", [show(A),show(B),show(C),show(D)]),
    false.

throw_err(Err) ->
    throw( {string,Err} ).
    %throw( Err ).

throw_expr(Expr) ->
    %throw( {string,Expr} ).
    throw( Expr ).

load_file_(Filename,[]) ->
    case l4u@resources:load(Filename) of
        undefined ->
            throw({error, {file_not_found, Filename}});
        Content ->
            Content
    end;

load_file_(Filename,[Dir | Rest]) ->
    %{ok,Raw} = file:read_file(Filename),
    Fname = to_char_list(Filename),
    case file:read_file(Dir ++ Fname) of
        {ok,Raw} -> Raw;
        _ -> load_file_(Filename,Rest)
    end.
            
load_file(Filename) ->
    load_file_(Filename,["","scripts/","scripts/lib/","scripts/tests/"]).

make_ref(Value) ->
    Ref = make_ref(),
    put(Ref, Value),
    Ref.

deref(Ref) ->
    get(Ref).

reset_ref(Ref, Value) ->
    Result = get(Ref),
    put(Ref, Value),
    Result.

show({string,Value}) ->
    Value;
show(Value) when is_binary(Value) ->
    Value;
show(Value) ->
    fmtp(Value).

fmtp(Value) -> 
    list_to_binary( lists:flatten( io_lib:format("~p", [Value]) ) ).

abbreviate(X) -> X;

abbreviate(X) when is_list(X) ->
    list:map( fun abbreviate/1, X );

abbreviate(X) when is_tuple(X) ->
    case tuple_to_list(X) of
        ['env' | Rest] -> [env,'***'];
        ['scope' | Rest] -> [scope,'***'];
        %['bif' | Rest] -> [bif,'***'];
        _ -> X
    end,
    list_to_tuple( list:map( fun abbreviate/1, X ) ).

internal_form(Value) ->
    case 'NOP' of
        'NOP' -> <<"">>;
    %list_to_binary( io_lib:format("~p", [abbreviate(Value)]) ).
    %list_to_binary( io_lib:format("~p", [Value] ).
        _ -> <<"**">>
    end.

bflatten([],Acc) ->
    string:join(lists:reverse(Acc),"");
bflatten([H | T],Acc) ->
    bflatten(T, [bflatten(H,[]) | Acc]);
bflatten(X,Acc) ->
    [X | Acc].

bflatten(X) ->
    bflatten(X,[]).


norl4uize_string(X) when is_list(X) ->
    string:join( lists:map( fun norl4uize_string/1, X ), "" );
norl4uize_string(X) when is_binary(X) ->
    X.


pretty_print_native(Value) when is_list(Value) ->
    "[" ++ lists:map( fun(X) -> pretty_print_native(X) end, Value ) ++ "]";
pretty_print_native(Value) when is_tuple(Value) ->
    "#(" ++ lists:map( fun(X) -> pretty_print_native(X) end, tuple_to_list(Value) ) ++ ")";
pretty_print_native(Value) when is_binary(Value) ->
    io_lib:format("~ts", [Value]);
pretty_print_native(Value) when is_function(Value) ->
    "#<fn>";
pretty_print_native(Value) ->
    io_lib:format("~p", [Value]).


external_form_(Value) ->
    %io:format("external_form: ~p~n", [Value]),
    case Value of
        {native_value,<<"pid">>,PID} -> io_lib:format("#<PID ~p>",[PID]);
        {native_value,<<"ref">>,Content} -> io_lib:format("#<REF ~p>",[Content]);
        {native_value,ValueType,Content} -> io_lib:format("#<NativeValue ~ts>",[ValueType]);
        {native_function,FnName,Content} -> io_lib:format("#<NativeFunction ~ts>",[FnName]);
        _ ->
            fmtp(Value)
    end.

external_form(Value) ->
    %norl4uize_string( external_form_(Value) ).
    bflatten( external_form_(Value) ).


catch_ex(TryFn) ->
    try
        {ok, TryFn()}
    catch
        throw:ExReason:ExStackTrace ->    
            {error, {error_ex2,show(ExReason),<<"">>} };
        ExClass:ExReason:ExStackTrace ->
            %ErrorMsg = list_to_binary( io_lib:format("~p\n~p\n", [ExReason,ExStackTrace]) ),
            %{error,ErrorMsg}
            {error, {error_ex2,show(ExReason),show(ExStackTrace)} }
    end.

get_command_line_args() ->
    %init:get_argument().
    lists:map(
        fun(X) ->
            list_to_binary(X)
        end,    
        init:get_plain_arguments() ).

% 特殊文字をエスケープして表示可能な文字列にする
escape(String) ->
    escape_helper(String, []).

escape_helper([], Acc) ->
    lists:reverse(Acc);
escape_helper([Char | Rest], Acc) ->
    EscapedChar = case Char of
        32  -> " ";
        $\n -> "\\n";
        $\t -> "\\t";
        $\r -> "\\r";
        $\b -> "\\b";
        $\f -> "\\f";
        $\" -> "\\\"";
        $\\ -> "\\\\";
        _ -> [Char]
    end,
    escape_helper(Rest, [EscapedChar | Acc]).

% エスケープされた文字列を元の特殊文字を含む文字列に戻す
unescape(String) ->
    unescape_helper(String, [], false).

unescape_helper([], Acc, _) ->
    lists:reverse(Acc);
unescape_helper([Char | Rest], Acc, Escaped) ->
    {NextChar, NextEscaped} = case {Char, Escaped} of
        {92, false} -> {[], true}; % 92 is '\\'
        {92, true} -> {[92], false}; % '\\' for backslash
        {110, true} -> {[$\n], false}; % 'n' for newline
        {116, true} -> {[$\t], false}; % 't' for tab
        {114, true} -> {[$\r], false}; % 'r' for carriage return
        {98, true} -> {[$\b], false}; % 'b' for backspace
        {102, true} -> {[$\f], false}; % 'f' for form feed
        {34, true} -> {[$\"], false}; % '\"' for quote
        _ -> {[Char], false}
    end,
    unescape_helper(Rest, [NextChar | Acc], NextEscaped).

escape_binary_string(Str) ->
    CodePoints = unicode:characters_to_list(Str),
    EscapedCodePoints = escape(CodePoints),
    unicode:characters_to_binary(EscapedCodePoints).

unescape_binary_string(Str) ->
    CodePoints = unicode:characters_to_list(Str),
    UnescapedCodePoints = unescape(CodePoints),
    unicode:characters_to_binary(UnescapedCodePoints).

process_dict_set(PDic,Key,Value) ->
    put({PDic,Key},Value).

process_dict_get(PDic,Key) ->
    get({PDic,Key}).

process_dict_erase(PDic,Key) ->
    erase({PDic,Key}).

process_dict_keys(PDic) ->
    process_dict_keys( PDic,get_keys(),[] ).

process_dict_keys(_,[],Acc) -> Acc;

process_dict_keys(PDic,[{PDic,Key} | Keys],Acc) ->
    process_dict_keys(PDic,Keys,[Key | Acc]);

process_dict_keys(PDic,[_ | Keys],Acc) ->
    process_dict_keys(PDic,Keys,Acc).


tick_count() ->
    os:system_time().

unique_int() ->
 erlang:unique_integer([positive]).

unique_pdic() ->
 erlang:unique_integer().

aux_pdic(PDIC,ID) ->
 {PDIC,ID}.

unique_str() ->
    %{string, list_to_binary( lists:flatten( io_lib:format("$~w$",[ erlang:unique_integer([positive]) ]) ) ) }.
    list_to_binary( lists:flatten( io_lib:format("$_~w_$",[ erlang:unique_integer([positive]) ]) ) ).

compare_any(X,Y) ->
    case X < Y of
        true -> lt;
        false -> case X > Y of
            true -> gt;
            false -> eq
        end
    end.


erl_ref_native_fun(ModuleName,FunctionName) ->
    % check FunctionName contains the arity(function/arity)
    case string:split(FunctionName,<<"/">>) of
        [StrFName,StrArity] ->
            Module = binary_to_atom(ModuleName),
            FunName = binary_to_atom(StrFName),
            Arity = list_to_integer(binary_to_list(StrArity)),
            fun Module:FunName/Arity;

        _ ->
            { binary_to_atom(ModuleName), binary_to_atom(FunctionName) }
    end.

erl_fn_apply(FunDef,Args) when is_function(FunDef) ->
    %io:format("erl_fn_apply 1: ~ts ~ts~n", [show(FunDef),show(Args)]),
    Result = erlang:apply(FunDef,Args),
    %io:format("result = ~p\n", [Result]),
    Result;

erl_fn_apply({ModuleName,FunctionName},Args) ->
    %io:format("erl_fn_apply 2: ~ts ~ts ~ts~n", [show(ModuleName),show(FunctionName),show(Args)]),
    erlang:apply(ModuleName,FunctionName,Args).

erl_get_module_functions(ModuleName) ->
    %io:format("erl_get_module_functions: ~p~n", [ModuleName]),
    Module = binary_to_atom(ModuleName),
    %io:format("erl_get_module_functions: ~p~n", [Module]),
    %Functions = Module:module_info(functions),
    Functions = Module:module_info(exports),
    %io:format("erl_get_module_functions: ~p~n", [Functions]),
    lists:map( fun({Name,Arity})-> {atom_to_binary(Name),Arity } end, Functions).


os_cmd(Str) ->
    ChrList = binary_to_list(Str),
    ChrListResult = os:cmd(ChrList),
    Result = list_to_binary(ChrListResult).

erl_get_module_info(ModuleName) ->
    Module = to_symbol(ModuleName),
    io:format("module = ~p~n", [Module]),
    Module:module_info().

erl_get_nodes() ->
    {list, lists:map( fun(X) -> {native_value,<<"node">>, X} end, nodes() ) }.

erl_get_processes() ->
    {list, lists:map( fun(X) -> {native_value,<<"pid">>, X} end, processes() ) }.

stringify(X) ->
    list_to_binary( io_lib:format("~p", [X]) ).

error_to_string({error_ex2,Msg,Detail},false) ->
    show(Msg);

error_to_string({error_ex2,Msg,Detail},true) ->
    list_to_binary( io_lib:format("~ts\n~ts\n", [Msg,Detail]) );
    
error_to_string(Error,_) ->
    show(Error).

file_exists(FilePath) ->
    filelib:is_file(FilePath).

dir_exists(DirPath) ->
    filelib:is_dir(DirPath).

get_cwd() ->
    {ok,Dir} = file:get_cwd(),
    to_bin_string(Dir).

set_cwd(DirPath) ->
    file:set_cwd(DirPath).

abspath(FilePath) ->
    to_bin_string( filename:absolute_name(FilePath) ).