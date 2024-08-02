ExUnit.start()

defmodule NatsTestIex.TestHelper do
  def cdr_empty() do
    cdr_await_process(nil)
    # Allow old items in stream to propagate
    Process.sleep(999)
    NatsTestIex.CDR.get() |> cdr_await_empty("")
  end

  def cdr_get_one(), do: NatsTestIex.CDR.get() |> cdr_get_one()

  def cdr_pull_start(config) do
    s = Kernel.self()
    pid = Process.spawn(fn -> cdr_pull_start_wait(config, s) end, [])

    receive do
      {:started, ^pid} -> :ok
    end

    pid
  end

  def cdr_pull_stop(pid, kind) do
    # Allow old items in stream to propagate
    Process.sleep(999)
    NatsTestIex.CDR.get() |> cdr_await_empty("stop")
    Process.exit(pid, kind)
    Process.alive?(pid) |> cdr_pull_await_exit(pid)
  end

  #
  # Internal functions
  #

  defp cdr_await_empty([], _), do: :ok

  defp cdr_await_empty([old], label) do
    IO.puts("Unempty CDR #{label}: #{Kernel.inspect(old)}")
    NatsTestIex.CDR.get() |> cdr_await_empty(label)
  end

  defp cdr_await_process(nil), do: NatsTestIex.CDR |> Process.whereis() |> cdr_await_process()
  defp cdr_await_process(_), do: :ok

  defp cdr_get_one([]) do
    Process.sleep(999)
    NatsTestIex.CDR.get() |> cdr_get_one()
  end

  defp cdr_get_one([one]), do: one

  defp cdr_pull_await_exit(true, pid), do: Process.alive?(pid) |> cdr_pull_await_exit(pid)
  defp cdr_pull_await_exit(false, _pid), do: Process.sleep(999)

  defp cdr_pull_start_wait(config, reply_to) do
    _ = NatsTestIex.CDRPullConsumer.start_link(config)
    Process.send(reply_to, {:started, Kernel.self()}, [])
    Process.sleep(100_000)
  end
end
