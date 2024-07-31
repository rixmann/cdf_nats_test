defmodule NatsTestIex.RestartTest do
  use ExUnit.Case

  @moduletag timeout: 10_000

  test "CDR started" do
    assert Process.alive?(Process.whereis(NatsTestIex.CDR))
  end

  test "CDR working" do
    m = %{n: 0, apn: "zero"}
    NatsTestIex.CDR.arrived(m)
    cdr = get_one([])
    assert cdr === m
  end

  test "publish one" do
    pid = Process.spawn(fn -> start_wait() end, [])
    m = %{n: 1, apn: "one"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    cdr = get_one([])
    empty = NatsTestIex.CDR.get()
    Process.exit(pid, :one)
    assert cdr === m
    assert empty === []
  end

  test "publish two" do
    pid = Process.spawn(fn -> start_wait() end, [])
    m = %{n: 2, apn: "two"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    cdr = get_one([])
    empty = NatsTestIex.CDR.get()
    Process.exit(pid, :two)
    assert cdr === m
    assert empty === []
  end

  #
  # Internal functions
  #

  defp get_one([]) do
    Process.sleep(900)
    NatsTestIex.CDR.get() |> get_one()
  end

  defp get_one([one]), do: one

  defp start_wait() do
    _ = NatsTestIex.CDRPullConsumer.start_link(%{})
    Process.sleep(100_000)
  end
end
