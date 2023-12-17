-module(l4u@bif_file_ffi).
-include_lib("kernel/include/file.hrl").
%-compile(export_all).
-export([scan_directory/1, scan_directory/2]).

% 公開関数: ディレクトリとデフォルトの深さ9999を使用してスキャン
scan_directory(Dir) ->
    scan_directory(Dir, 9999).

% 公開関数: 指定された深さでディレクトリをスキャン
scan_directory(Dir, MaxDepth) ->
    scan_directory(Dir, MaxDepth, 0).

% 内部関数: 実際のスキャン処理
scan_directory(Dir, MaxDepth, CurrentDepth) when CurrentDepth =< MaxDepth ->
    case file:list_dir(Dir) of
        {ok, Files} ->
            lists:foldl(
                fun(File, Acc) ->
                    FullPath = filename:join([Dir, File]),
                    case file:read_file_info(FullPath) of
                        {ok, #file_info{type = directory}} ->
                            Acc ++ [FullPath] ++ scan_directory(FullPath, MaxDepth, CurrentDepth + 1);
                        {ok, _} ->
                            Acc ++ [FullPath];
                        {error, _} ->
                            Acc
                    end
                end,
                [],
                Files
            );
        {error, _} ->
            []
    end;
scan_directory(_Dir, _MaxDepth, _CurrentDepth) ->
    [].
