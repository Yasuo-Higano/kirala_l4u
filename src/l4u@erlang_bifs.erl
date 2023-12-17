-module(l4u@erlang_bifs).
-compile(export_all).
-import(l4u_ffi, [unsafe_corece/1, to_char_list/1, to_bin_string/1, to_l4u_string/1, to_symbol/1, l4u_to_native/1,native_to_l4u/1]).


return(Env,Expr) ->
  {with_env,Expr,Env}.

bif_sh([Arg1],Env) ->
  return(Env, to_l4u_string( os:cmd(to_char_list(Arg1)) ) ).

erlang_bifs() ->
  Bif = fun(NameStr, F) ->
    Name = to_bin_string(NameStr),
    { Name, {bif,Name, F} } end,

  Bsf = fun(NameStr, F) ->
    Name = to_bin_string(NameStr),
    { Name, {bispform,Name, f} } end,

  [ Bif("sh*",fun bif_sh/2) ].
 