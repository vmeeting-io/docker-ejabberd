%%%-------------------------------------------------------------------
%%% @author Magnus Henoch <henoch@dtek.chalmers.se>
%%%
%%% Copyright (C) 2002-2021 ProcessOne, SARL. All Rights Reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%%-------------------------------------------------------------------
-module(xmpp_sasl_anonymous).
-behaviour(xmpp_sasl).
-protocol({xep, 175, '1.2'}).

-export([mech_new/6, mech_step/2, format_error/1]).

-include("logger.hrl").
-include("ejabberd_http.hrl").
-include_lib("xmpp/include/xmpp.hrl").

-record(state, {ws_pid :: binary(), host :: binary()}).

-type error_reason() :: not_authorized.
-export_type([error_reason/0]).

-spec format_error(error_reason()) -> {atom(), binary()}.
format_error(not_authorized) ->
    {'not-authorized', <<"Invalid jitsi jwt token">>}.


mech_new(_Mech, SocketState, Host, _GetPassword, _CheckPassword, _CheckPasswordDigest) ->
    % TODO: a better method to extract socketPID
    SocketPID = element(2, element(3, SocketState)),
    #state{ws_pid = SocketPID, host = Host}.

mech_step(#state{ws_pid = SocketPID, host = Host}, _ClientIn) ->
    User = iolist_to_binary([p1_rand:get_string(),
                             integer_to_binary(p1_time_compat:unique_integer([positive]))]),

    WS = ejabberd_http_ws:get_ws(SocketPID),
    Query = WS#ws.q,
    JWTResult = ejabberd_hooks:run_fold(check_jwt_token, Host, ok, [Query, Host]),

    if
        JWTResult == ok ->
            {ok, [{username, User},
            {authzid, User},
            {auth_module, anonymous}]};
        true ->
            {error, not_authorized, User}
    end.

