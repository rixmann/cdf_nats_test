defmodule NatsTestIexTest do
  use ExUnit.Case
  doctest NatsTestIex

  test "greets the world" do
    assert NatsTestIex.hello() == :world
  end
end
