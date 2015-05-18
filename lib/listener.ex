defmodule Listener do
  use GenServer
	@name __MODULE__
  def init(:ok) do {:ok, []} end
  def start_link() do GenServer.start_link(__MODULE__, :ok, [name: @name]) end
  def export(l) do    GenServer.call(@name, {hd(l), self(), tl(l)}) end
  def handle_call({type, s, args}, _from, _) do
    spawn(fn() ->     GenServer.reply(_from, main(type, args)) end)
    {:noreply, []}
  end
  def main(type, args) do
    case type do
      "add_blocks" -> BlockAbsorber.absorb(hd(args))
      "pushtx" -> fee_filter(hd(args))
      "txs" -> Mempool.txs
      "height" -> KV.get("height")
      "block" -> Blockchain.get_block(hd(args))
      "blocks" -> flip(blocks(hd(args), hd(tl(args))))
      "add_peer" -> Peers.add_peer(hd(args))
      "all_peers" -> Peers.get_all
      "status" ->
          h = KV.get("height")
          block = Blockchain.get_block(h)
          if block.data==nil do block = %{data: 1} end
          [height: h, hash: DetHash.doit(block.data)]
      x -> IO.puts("listner is not a command #{inspect x}")
    end
  end
  def fee_filter(tx) do
    cond do
      tx[:data][:fee]<10000 -> "low-fee tx are blocked on this node"
      true -> Mempool.add_tx(tx)
    end
  end
  def flip(x, y \\ []) do
    cond do
      x==[] -> y
      true -> flip(tl(x), [hd(x)|y])
    end
  end
  def max do 10000 end
  def blocks(start, finish, out \\ []) do
    finish = min(finish, KV.get("height"))
    blocks_helper(start, finish, out)
  end
  def blocks_helper(start, finish, out) do
    block = Blockchain.get_block(start)
    cond do
      byte_size(PackWrap.pack(out)) > max -> tl(out)
      start < 0 -> blocks(1, finish, out)
      start > finish -> out
      block == nil -> blocks_helper(start+1, finish, out)
      true -> blocks_helper(start+1, finish, [block|out])
    end
  end
end