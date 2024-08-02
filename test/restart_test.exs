defmodule NatsTestIex.RestartTest do
  use ExUnit.Case

  @moduletag timeout: 10_000

  test "pull consumer maintenece, when using ack" do
    pull_consumer_maintenece(:ack)
  end

  test "pull consumer maintenece, when using noreply" do
    pull_consumer_maintenece(:noreply)
  end

  #
  # Internal functions
  #

  defp pull_consumer_maintenece(reply) do
    pid1 = NatsTestIex.TestHelper.cdr_start(%{reply: reply})
    m1 = %{apn: "first_pull_consumer_" <> Atom.to_string(reply)}
    Gnat.pub(:gnat, "one_cdr", :erlang.term_to_binary(m1))
    cdr1 = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    assert cdr1 === m1
    assert empty === []

    # maintenece
    NatsTestIex.TestHelper.cdr_stop(pid1, :first_pull_consumer_ack)
    NatsTestIex.cdr_consumer_delete()
    m2 = %{apn: "second_pull_consumer_ack"}
    Gnat.pub(:gnat, "one_cdr", :erlang.term_to_binary(m2))

    # max_ack_pending default is 20000
    {:ok, _} = NatsTestIex.cdr_consumer_create(20_000)
    pid2 = NatsTestIex.TestHelper.cdr_start(%{reply: reply})
    cdr2 = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_stop(pid2, :second_pull_consumer_ack)
    assert cdr2 === m2
    assert empty === []
  end
end
