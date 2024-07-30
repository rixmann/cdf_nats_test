defmodule NatsTestIexTest do
  use ExUnit.Case

  @moduletag timeout: 5000

  test "CDR started" do
    assert Process.alive?(Process.whereis(NatsTestIex.CDR))
  end

  test "CDR working" do
    m = %{n: 0, apn: "kalle"}
    NatsTestIex.CDR.arrived(m)
    cdr = get_one([])
    assert cdr === m
  end

  test "publish one" do
    pid = Process.spawn(fn -> start_wait() end, [])
    on_exit(fn -> Process.exit(pid, :exit) end)
    m = %{n: 1, apn: "kalle"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    cdr = get_one([])
    empty = NatsTestIex.CDR.get()
    assert cdr === m
    assert empty === []
    Process.exit(pid, :exit)
  end

  test "publish two" do
    pid = Process.spawn(fn -> start_wait() end, [])
    on_exit(fn -> Process.exit(pid, :exit) end)
    m = %{n: 2, apn: "kalle"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    cdr = get_one([])
    empty = NatsTestIex.CDR.get()
    assert cdr === m
    assert empty === []
    Process.exit(pid, :exit)
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
    _ = NatsTestIex.CDRPullConsumer.start_link(:ignore)
    Process.sleep(5_000)
  end
end
