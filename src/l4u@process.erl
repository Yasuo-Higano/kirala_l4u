-module(l4u@process).
-behavior(gen_server).
-compile(export_all).
-record(state, {env}).
-define(DEFAULT_TIMEOUT, infinity).

%%
%% Public API
%%

% Initializer() -> Env
new_process(Initializer) ->
    case gen_server:start(?MODULE, [Initializer], []) of
        {ok, Pid} -> {ok,Pid};
        {error, Reason} -> {error,Reason}
    end.

% WithEnv(expr,env)を返す関数を実行する
% fn() -> WithEnv(expr,env)
exec(Pid, Fn) ->
    %io:format("call exec: ~p~n", [Fn]),
    gen_server:call(Pid, {exec, Fn},?DEFAULT_TIMEOUT).

% Fn(Env) -> Value
% exec_native(Pid, Fn) -> Result(Value,Error)
exec_native(Pid, Fn) ->
    %io:format("call exec: ~p~n", [Fn]),
    gen_server:call(Pid, {native_exec, Fn},?DEFAULT_TIMEOUT).

get_env(Pid) ->
    {ok,Env} = gen_server:call(Pid, get_env,?DEFAULT_TIMEOUT),
    Env.

%%
%% gen_server callbacks
%%

init([Initializer]) ->
    Env = Initializer(),
    {ok, #state{env=Env}}.

handle_call({exec, Fn}, _From, State) ->
    try
        %io:format("executing: ~p~n", [Fn]),
        {with_env,Expr,Env} = Fn(State#state.env),
        {reply,{ok, Expr}, #state{env=Env}}
    catch ECls:EMsg:EStacktrace ->
        {reply, {error,EMsg}, State}
    end;

handle_call({native_exec, Fn}, _From, State) ->
    try
        Result = Fn(State#state.env),
        {reply,{ok, Result}, State}
    catch ECls:EMsg:EStacktrace ->
        {reply, {error,EMsg}, State}
    end;

handle_call(get_env, _From, State) ->
    {reply,{ok, State#state.env}, State};

handle_call(terminate, _From, State) ->
    {stop, norl4u, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Msg, State) ->
    error_logger:info_msg("unexpected message: ~p~n", [Msg]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
