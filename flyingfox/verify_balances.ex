defmodule VerifyBalances do
  def all_positive(a) do
    cond do
      a==[] -> true
      true -> all_positive_1(a)
    end
  end
  def all_positive_1(addresses) do
    [{_, t}|tail] = addresses
    cond do
      t<0 -> false
      tail==[] -> true
      true -> all_positive_1(tail)
    end
  end
  def modify_balance(addresses, pub, f) do
    key = String.to_atom(pub)
    balance=Dict.get(addresses, key)
    balance=f.(balance)
    Dict.put(addresses, key, balance)
  end
  def lose_key(address, pub, amount, key) do
    if is_binary(key) do key = String.to_atom(key) end
    f = fn(balance) ->
      Dict.put(balance, key, Dict.get(balance, key)-amount) 
    end
    modify_balance(address, pub, f)
  end
  def lose_cash(address, pub, amount) do
    lose_key(address, pub, amount, "cash")
  end
  def lose_bond(address, pub, amount) do
    lose_key(address, pub, amount, "bond")
  end
  def positive_balances(txs, bond_size, block_creator, addresses \\ []) do
    if block_creator != nil and not(block_creator in Dict.keys(addresses)) do
      acc = KV.get(block_creator)
      balance = [cash: acc[:amount], bond: acc[:bond]]      
      addresses = [{String.to_atom(block_creator), balance}|addresses]#to_atom is dangerous!!
    end
    cond do
      txs==[] -> 
        if block_creator != nil do addresses = lose_cash(addresses, block_creator, Constants.block_creation_fee) end
        all_positive(addresses)
      true -> positive_balances_1(txs, bond_size, block_creator, addresses)
    end
  end
  def positive_balances_1(txs, bond_size, block_creator, addresses) do
    [tx|txs]=txs
    pub=tx[:pub]
    type=tx[:data][:type]
    if not pub in Dict.keys(addresses) do
      acc = KV.get(pub)
      balance = [cash: acc[:amount], bond: acc[:bond]]
      addresses = [{String.to_atom(pub), balance}|addresses]#to_atom is dangerous!!!
    end
    cond do
      type == "spend" ->
        addresses = lose_cash(addresses, pub, tx[:data][:amount]+tx[:data][:fee])
      type == "spend2wait" ->
        addresses = lose_cash(addresses, pub, tx[:data][:amount]+tx[:data][:fee])
      type == "wait2bond" ->
        addresses = lose_cash(addresses, pub, tx[:data][:fee])
      type == "bond2spend" ->
        addresses = lose_bond(addresses, pub, tx[:data][:amount])
        addresses = lose_cash(addresses, pub, tx[:data][:fee])
      type == "sign" ->
        addresses = lose_bond(addresses, pub, bond_size*length(tx[:data][:winners]))
      type in [:slasher, :reveal, :sign] -> true
      true -> 
        IO.puts("no function with that name")
        true
    end
    positive_balances(txs, bond_size, block_creator, addresses)
  end
end
