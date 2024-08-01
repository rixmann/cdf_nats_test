defmodule NatsTestIex.RestartTest do
  use ExUnit.Case

  @moduletag timeout: 10_000

  test "CDR started" do
    assert Process.alive?(Process.whereis(NatsTestIex.CDR))
  end

  test "publish one ack" do
    pid = NatsTestIex.TestHelper.cdr_start(%{reply: :ack, testcase: :one_ack})
    m = %{n: 11, apn: "one_ack"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    Process.sleep(200)
    cdr = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_stop(pid, :one_ack)
    assert cdr === m
    assert empty === []
  end

  test "publish one noreply" do
    pid = NatsTestIex.TestHelper.cdr_start(%{reply: :noreply, testcase: :one_noreply})
    m = %{n: 12, apn: "one_noreply"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    Process.sleep(200)
    cdr = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_stop(pid, :one_noreply)
    assert cdr === m
    assert empty === []
  end

  test "publish two" do
    pid = NatsTestIex.TestHelper.cdr_start(%{testcase: :two})
    m = %{n: 2, apn: "two"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    Process.sleep(200)
    cdr = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_stop(pid, :two)
    assert cdr === m
    assert empty === []
  end
end
