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
    IO.inspect(List.duplicate(0, n))
  end
end

Solution.main()
