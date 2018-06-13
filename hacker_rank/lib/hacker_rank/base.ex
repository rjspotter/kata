defmodule HackerRankBase do

  def do_read do
    IO.gets("") |> String.trim
  end

  def do_read_int do
    do_read() |> String.to_integer
  end

  def do_read_all do
    IO.read(:stdio, :all) |> String.split
  end

  def do_read_all_int do
    do_read_all() |> Enum.map(&(String.to_integer/1))
  end

end

defmodule Solution do

  import HackerRankBase

  def main do
    lst = do_read_all_int()
    out = lst
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.map(fn(x) -> Enum.take(x, -1) end)
    |> List.flatten
    Enum.each(out, &(IO.puts/1))
  end
end

Solution.main()
