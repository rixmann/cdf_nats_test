defmodule NatsTestIex.FlowControlTest do
  use ExUnit.Case

  test "ack_wait" do
    Jetstream.API.Consumer.info(:gnat, "CDR", "CDR") |> Kernel.inspect() |> IO.puts()
  end

  test "stop at four" do
    n = 4
    :ok = NatsTestIex.cdr_consumer_delete()
    {:ok, _} = NatsTestIex.cdr_consumer_create(n)
    pid = NatsTestIex.TestHelper.cdr_start(%{reply: :noreply})
    pub(20)
    :ok = stop_arriving_at(n)
    arrived = NatsTestIex.CDR.count()
    assert arrived === n
    :ok = empty_queue(20)
    NatsTestIex.TestHelper.cdr_stop(pid, :ten)
  end

  #
  # Internal functions
  #

  defp stop_arriving_at(n), do: NatsTestIex.CDR.count() |> stop_arriving_at(n)
  defp stop_arriving_at(c, n) when c < n, do: stop_arriving_at(n)
  defp stop_arriving_at(_, _), do: :ok

  defp empty_queue(0), do: :ok
  defp empty_queue(n) do
    NatsTestIex.TestHelper.cdr_get_one()
    IO.puts("arrived: #{n}")
    empty_queue(n - 1)
  end

  defp pub(0), do: :ok

  defp pub(n) do
    m = %{n: n, apn: "#{n}"}
    Gnat.pub(:gnat, "cdr", :erlang.term_to_binary(m))
    pub(n - 1)
  end
end
