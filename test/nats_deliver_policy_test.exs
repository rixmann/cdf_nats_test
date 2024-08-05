defmodule NatsTestIex.NatsDeliveryPolicyTest do
  use ExUnit.Case

  @moduletag timeout: 20_000

  test "deliver policy" do
    apn = "deliver_policy"
    pid1 = NatsTestIex.TestHelper.cdr_pull_start(%{reply: :ack, testcase: apn})
    m1 = %{apn: apn}
    Gnat.pub(:gnat, "one_cdr", :erlang.term_to_binary(m1))
    cdr1 = NatsTestIex.TestHelper.cdr_get_one()
    empty = NatsTestIex.CDR.get()
    assert cdr1 === m1
    assert empty === []
    NatsTestIex.TestHelper.cdr_pull_stop(pid1, String.to_atom(apn))

    IO.puts "starting new consumer"
    NatsTestIex.cdr_consumer_create(20_000, %{delivery_policy: :all, deliver_policy: :all})
    pid2 = NatsTestIex.TestHelper.cdr_pull_start(%{reply: :ack, testcase: apn})
    assert cdr1 === NatsTestIex.TestHelper.cdr_get_one()
    assert [] === NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_pull_stop(pid2, String.to_atom(apn))

    IO.puts "starting final consumer"
    NatsTestIex.cdr_consumer_create(20_000, %{delivery_policy: :new, deliver_policy: :new})
    pid3 = NatsTestIex.TestHelper.cdr_pull_start(%{reply: :ack, testcase: apn})
    Process.sleep(100)
    assert [] === NatsTestIex.CDR.get()
    NatsTestIex.TestHelper.cdr_pull_stop(pid3, String.to_atom(apn))
    
  end

  #
  # Internal functions
  #
end
