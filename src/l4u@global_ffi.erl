-module(l4u@global_ffi).
-compile(export_all).

get_with_default(Key,DefaultValue) ->
    case persistent_term:get(Key) of
        undefined ->
            DefaultValue;
        Value ->
            Value
    end.