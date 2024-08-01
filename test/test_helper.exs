ExUnit.start()

defmodule NatsTestIex.TestHelper do
  def cdr_get_one(), do: NatsTestIex.CDR.get() |> cdr_get_one()
  def cdr_start() do
    res = Process.spawn(fn -> cdr_start_wait(%{}) end, [])
    Process.sleep(999)
    res
  end
  def cdr_start(config) do
    res = Process.spawn(fn -> cdr_start_wait(config) end, [])
    Process.sleep(999)
    res
  end
  def cdr_stop(pid, kind) do
    res = Process.exit(pid, kind)
    Process.sleep(10)
    res
  end

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
