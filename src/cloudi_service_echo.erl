-module(cloudi_service_echo).
-behaviour(cloudi_service).

% cloudi service callbacks
-export([cloudi_service_init/3,
         cloudi_service_handle_request/11,
         cloudi_service_handle_info/3,
         cloudi_service_terminate/2]).

-include_lib("cloudi_core/include/cloudi_logger.hrl").
-include_lib("cloudi_core/include/cloudi_service_children.hrl").

-record(state, {
        listener,
        service
    }).

cloudi_service_init(_Args, Prefix, Dispatcher) ->
    Service = cloudi_service:self(Dispatcher),
    {ok, ListenerPid} = cloudi_x_ranch:start_listener(
        Service, % Ref
        100, % Number of acceptor processes
        cloudi_x_ranch_tcp, % Transport
        [{port, 5555}, % TransOpts
         {max_connections, 1024}],
        echo_protocol, % Protocol
        [{dispatcher, cloudi_service:dispatcher(Dispatcher)}, % ProtoOpts
         {context, create_context(Dispatcher)}, % cf cloudi_service_children.hrl
         {prefix, Prefix}]
    ),
    {ok, #state{listener = ListenerPid,
                service = Service}}.

cloudi_service_handle_request(_Type, _Name, _Pattern, _RequestInfo, _Request,
                              _Timeout, _Priority, _TransId, _Pid,
                              State, _Dispatcher) ->
    {reply, <<>>, State}.

cloudi_service_handle_info(Request, State, _) ->
    ?LOG_WARN("Unknown info \"~p\"", [Request]),
    {noreply, State}.

cloudi_service_terminate(_, #state{service = Service}) ->
    cloudi_x_ranch:stop_listener(Service),
    ok.
