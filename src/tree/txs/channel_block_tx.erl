%Channel blocks need to be rethought a little.
%We need to add a third signature, to lock in the secret_hashes. 
%The fee and oracle judgement should be signed by the third signature, but not the first 2.
%Channel_slasher needs to be upgraded so that you can slash someone, not just for publishing a low-nonced channel block, but also for failing to provide some evidence.
%SignedCB = #signed{data = channel_block, sig1 = signature, sig2 = signature, revealed = [evidence]}
%#signed{data = #signed_channel_block{channel_block = SignedCB, fee = 100}, sig1 = signature}.

-module(channel_block_tx).
-export([doit/7, origin_tx/3, channel/7, channel_block/5, cc_losses/1, close_channel/4, id/1, delay/1, nonce/1, publish_channel_block/3, make_signed_cb/4]).
-record(channel_block, {acc1 = 0, acc2 = 0, amount = 0, nonce = 0, bets = [], id = 0, fast = false, delay = 10, expiration = 0, nlock = 0, fee = 0}).
-record(signed_cb, {acc = 0, nonce = 0, channel_block = #channel_block{}, fee = 0}).
-record(bet, {amount = 0, merkle = <<"">>, default = 0}).%signatures
-record(tc, {acc1 = 0, acc2 = 0, nonce = 0, bal1 = 0, bal2 = 0, consensus_flag = false, fee = 0, id = -1, increment = 0}).
%`merkle` is the merkle root of a datastructure explaining the bet.
%`default` is the part of money that goes to participant 2 if the bet is still locked when the channel closes. Extra money goes to participant 1.
%There are at least 4 types of bets: hashlock, oracle, burn, and signature;. 
make_signed_cb(Acc, CB, Fee, Evidence) ->
    A = block_tree:account(Acc),
    Nonce = accounts:nonce(A),
    Tx = #signed_cb{acc = Acc, nonce = Nonce + 1, channel_block = CB, fee = Fee},
    sign:set_revealed(keys:sign(Tx), Evidence).
nonce(X) -> X#channel_block.nonce.
id(X) -> X#channel_block.id.
delay(X) -> X#channel_block.delay.
close_channel(Id, Amount, Nonce, Fee) ->
    Channel = block_tree:channel(Id),
    keys:sign(#channel_block{acc1 = channels:acc1(Channel), acc2 = channels:acc2(Channel), amount = Amount, nonce = Nonce, id = Id, fast = true, fee = Fee}).
cc_losses(Txs) -> cc_losses(Txs, 0).%filter out channel_block, channel_slash, and channel_close type txs. add up the amount of money in each such channel. 
cc_losses([], X) -> X;
cc_losses([SignedTx|T], X) -> 
    Tx = sign:data(SignedTx),
    case element(1, Tx) of
	signed_cb ->
	    SCBTx = sign:data(SignedTx),
	    STx = SCBTx#signed_cb.channel_block,
	    Tt = sign:data(STx),
	    Channel = block_tree:channel(Tt#channel_block.id, dict:new()),
	    SA = channels:bal1(Channel) + channels:bal2(Channel),
	    cc_losses(T, X+SA);
	channel_slash ->
	    cc_losses([channel_slash_tx:channel_block(Tx)|T], X);
	channel_close ->
	    Id = channel_close_tx:id(Tx),
	    Channel = block_tree:channel(Id, dict:new()),
	    SA = channels:bal1(Channel) + channels:bal2(Channel),
	    cc_losses(T, X+SA);
	_ -> cc_losses(T, X)
    end.
    
creator([], _) -> sign:empty(#tc{});
creator([SignedTx|T], Id) ->
    Tx = sign:data(SignedTx),
    Type = element(1, Tx),
    if
	Type == timeout ->
	    SSignedCB = channel_timeout_tx:channel_block(Tx),
	    CB = sign:data(SSignedCB),
	    %SCB = SignedCB#signed_cb.channel_block,
	    %CB = sign:data(SCB),
	    I = CB#channel_block.id,
	    if 
		I == Id -> SignedTx;
		true -> creator(T, Id)
	    end;
	true ->
	    creator(T, Id)
    end.
bet_amount(X) -> bet_amount(X, 0).
bet_amount([], X) -> X;
bet_amount([Tx|Txs], X) -> bet_amount(Txs, X+Tx#bet.amount).
channel_block(Id, Amount, Nonce, Delay, Fee) ->
    true = Delay < constants:max_reveal(),
    Channel = block_tree:channel(Id),
    keys:sign(#channel_block{acc1 = channels:acc1(Channel), acc2 = channels:acc2(Channel), amount = Amount, nonce = Nonce, id = Id, fast = false, delay = Delay, fee = Fee}).
publish_channel_block(CB, Fee, Evidence) ->
    ID = keys:id(),
    tx_pool:absorb(keys:sign(make_signed_cb(ID, CB, Fee, Evidence))).
origin_tx(BlockNumber, ParentKey, ID) ->
    OriginBlock = block_tree:read_int(BlockNumber, ParentKey),
    OriginTxs = block_tree:txs(OriginBlock),
    creator(OriginTxs, ID).
doit(Tx, ParentKey, Channels, Accounts, TotalCoins, S, NewHeight) ->
    CB = sign:data(Tx#signed_cb.channel_block),
    true = CB#channel_block.fast,%If fast is false, then you have to use close_channel instead. 
    A = Tx#signed_cb.acc,
    Acc = block_tree:account(A, ParentKey, Accounts),
    NAcc = accounts:update(Acc, NewHeight, -Tx#signed_cb.fee, 0, 1, TotalCoins),
    NewAccounts = dict:store(A, NAcc, Accounts),
    Nonce = accounts:nonce(NAcc),
    Nonce = Tx#signed_cb.nonce,
    channel(Tx#signed_cb.channel_block, ParentKey, Channels, NewAccounts, TotalCoins, S, NewHeight).

channel(SignedTx, ParentKey, Channels, Accounts, TotalCoins, S, NewHeight) ->
    Tx = sign:data(SignedTx),
    %io:fwrite(packer:pack(SignedCB)),
    %io:fwrite("\n"),
    %SCB = sign:data(SignedCB),
    %Tx = sign:data(SignedCB#signed_cb.channel_block),
    Acc1 = block_tree:account(Tx#channel_block.acc1, ParentKey, Accounts),
    Acc2 = block_tree:account(Tx#channel_block.acc2, ParentKey, Accounts),
    Channel = block_tree:channel(Tx#channel_block.id, ParentKey, Channels),
    FChannel = channels:read_channel(Tx#channel_block.id),
    AccN1 = Tx#channel_block.acc1,
    AccN1 = channels:acc1(Channel),
    AccN2 = Tx#channel_block.acc2,
    AccN2 = channels:acc2(Channel),
    StartAmount = channels:bal1(Channel) + channels:bal2(Channel),
    BetAmount = bet_amount(Tx#channel_block.bets),
    true = Tx#channel_block.amount + BetAmount < StartAmount + 1,
    true = BetAmount - Tx#channel_block.amount < StartAmount + 1,
    true = (Tx#channel_block.expiration == 0) or (Tx#channel_block.expiration > NewHeight),    
    true = (Tx#channel_block.nlock < NewHeight),
    A1 = Tx#channel_block.acc1,
    A2 = Tx#channel_block.acc2,
    B1 = channels:acc1(FChannel),
    B2 = channels:acc2(FChannel),
    Type = channels:type(Channel),
    if
	not ((B1 == A1) and
	(B2 == A2)) ->
	    D2 = 0,
	    D1 = 0;
	delegated_1 == Type ->
	    io:fwrite("bad \n"),
	    D1 = StartAmount,
	    D2 = 0;
	Type == delegated_2 ->
	    D2 = StartAmount,
	    D1 = 0;
	Type == non_delegated ->
	    D2 = 0,
	    D1 = 0
    end,
    N1 = accounts:update(Acc1, NewHeight, channels:bal1(Channel) + Tx#channel_block.amount, -D1, 0, TotalCoins),
    N2 = accounts:update(Acc2, NewHeight, channels:bal2(Channel) - Tx#channel_block.amount, -D2, 0, TotalCoins),
    MyKey = keys:pubkey(),
    APub1 = accounts:pub(Acc1),
    APub2 = accounts:pub(Acc2),
    if
	(APub1 == MyKey) or (APub2 == MyKey) -> my_channels:remove(Tx#channel_block.id);
	true -> 1=1
    end,
    NewChannels = dict:store(Tx#channel_block.id, channels:empty(),Channels),
    NewAccounts1 = dict:store(Tx#channel_block.acc1, N1, Accounts),
    NewAccounts2 = dict:store(Tx#channel_block.acc2, N2, NewAccounts1),
    {NewChannels, NewAccounts2, TotalCoins, S}.%remove money from totalcoins that was deleted in bets.

