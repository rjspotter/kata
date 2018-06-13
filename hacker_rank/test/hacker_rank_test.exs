defmodule HackerRankTest do
  use ExUnit.Case
  doctest HackerRank

  test "greets the world" do
    assert HackerRank.hello() == :world
  end
end
