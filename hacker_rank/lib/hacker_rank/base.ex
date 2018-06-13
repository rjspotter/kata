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
    out = my_filter(lst, fn(x) -> x < n end)
    Enum.each(out, &(IO.puts/1))
  end

  def my_filter(input, fun) do
    my_filter(input, fun, [])
  end

  def my_filter([], _fun, acc) do
    Enum.reverse(acc)
  end

  def my_filter([x | input], fun, acc) do
    if fun.(x) do
      my_filter(input, fun, [x | acc])
    else
      my_filter(input, fun, acc)
    end
  end


end

Solution.main()
