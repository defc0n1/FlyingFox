-module(internal_handler).

-export([init/3, handle/2, terminate/3]).
%example of talking to this handler:
%httpc:request(post, {"http://127.0.0.1:3011/", [], "application/octet-stream", "echo"}, [], []).
%curl -i -d '[-6,"test"]' http://localhost:3011

handle(Req, State) ->
    {ok, Data, _} = cowboy_req:body(Req),
    D = packer:pack(doit(packer:unpack(Data))),
    Headers = [{<<"content-type">>, <<"application/octet-stream">>},
    {<<"Access-Control-Allow-Origin">>, <<"*">>}],
    {ok, Req2} = cowboy_req:reply(200, Headers, D, Req),
    {ok, Req2, State}.
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
terminate(_Reason, _Req, _State) -> ok.
doit({create_account, Pub, Amount, Fee}) -> 
    create_account_tx:create_account(Pub, Amount, Fee);
doit({spend, To, Amount, Fee}) ->
    spend_tx:spend(To, Amount, Fee);
doit({buy_block}) -> block_tree:buy_block();
doit({sign_block}) -> sign_tx:sign();
doit({sign, Tx}) -> {ok, keys:sign(Tx)};
doit({create_channel, Partner, Bal1, Bal2, Type, Fee}) ->
    to_channel_tx:create_channel(Partner, Bal1, Bal2, Type, Fee);
doit({to_channel, ChId, Inc1, Inc2, Fee}) ->
    to_channel_tx:to_channel(ChId, Inc1, Inc2, Fee);
doit({close_channel, ChId, Amount, Nonce, Fee}) ->
    channel_block_tx:close_channel(ChId, Amount, Nonce, Fee);
doit({sync, IP, Port}) ->
    io:fwrite("internal handler sync\n"),
    download_blocks:sync(IP, Port);
doit({pubkey}) -> {ok, keys:pubkey()};
doit({id}) -> {ok,  keys:id()};
doit({channel_id, Partner}) -> {ok, channel_manager:id(Partner)};
doit({new_pubkey, Password}) -> 
    io:fwrite("internal handler new pubkey\n"),
    keys:new(Password);
doit({channel_spend, ChId, Amount}) ->
    channel_manager:spend(ChId, Amount);
doit({channel_recieve, ChId, MinAmount, Ch}) ->
    channel_manager:recieve(ChId, MinAmount, Ch);
doit({test}) -> 
    {test_response};
doit(_) ->
    io:fwrite("don't know how to handle it \n"),
    io:fwrite("\n"),
    {error}.
