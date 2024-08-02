defmodule NatsTestIex.RestartTest do
  use ExUnit.Case

  @moduletag timeout: 20_000

  test "pull consumer maintenece, when using ack" do
    pull_consumer_maintenece(:ack)
  end

  test "pull consumer maintenece, when using noreply" do
    pull_consumer_maintenece(:noreply)
  end

  #
  # Internal functions
  #

  def pull_consumer_maintenece(reply) do
    apn = "first_pull_consumer_" <> Atom.to_string(reply)
    pid1 = NatsTestIex.TestHelper.cdr_pull_start(%{reply: reply, testcase: apn})
    m1 = %{apn: apn}
    Gnat.pub(:gnat, "one_cdr", :erlang.term_to_binary(m1))
    cdr1 = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    assert cdr1 === m1
    assert empty === []

    # maintenece
    NatsTestIex.TestHelper.cdr_pull_stop(pid1, String.to_atom(apn))
    apn = "second_pull_consumer_" <> Atom.to_string(reply)
    m2 = %{apn: apn}
    Gnat.pub(:gnat, "one_cdr", :erlang.term_to_binary(m2))

    pid2 = NatsTestIex.TestHelper.cdr_pull_start(%{reply: reply, testcase: apn})
    cdr2 = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_pull_stop(pid2, String.to_atom(apn))
    assert cdr2 === m2
    assert empty === []
  end
end
