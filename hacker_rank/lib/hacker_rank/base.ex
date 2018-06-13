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
    n = do_read_int()
    lst = do_read_all_int()
    out = repeater(n, lst)
    Enum.each(out, &(IO.puts/1))
  end

  def repeater(n, src) do
    repeater(n, src, [])
  end

  def repeater(_n, [], acc) do
    acc
    |> Enum.reverse
    |> List.flatten
  end

  def repeater(n, [x | src], acc) do
    repeater(n, src, [List.duplicate(x, n) | acc])
  end

end

Solution.main()
