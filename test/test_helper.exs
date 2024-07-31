ExUnit.start()

defmodule NatsTestIex.TestHelper do
  def cdr_get_one(), do: NatsTestIex.CDR.get() |> cdr_get_one()
  def cdr_start(), do: Process.spawn(fn -> cdr_start_wait(%{}) end, [])
  def cdr_start(config), do: Process.spawn(fn -> cdr_start_wait(config) end, [])
  def cdr_stop(pid, kind), do: Process.exit(pid, kind)

  #
  # Internal functions
  #

  defp cdr_get_one([]) do
    Process.sleep(900)
    NatsTestIex.CDR.get() |> cdr_get_one()
  end

  defp cdr_get_one([one]), do: one

  defp cdr_start_wait(config) do
    _ = NatsTestIex.CDRPullConsumer.start_link(config)
    Process.sleep(100_000)
  end
end
