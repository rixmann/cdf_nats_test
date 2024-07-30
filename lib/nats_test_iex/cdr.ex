defmodule NatsTestIex.CDR do
  use GenServer

  def arrived(cdr), do: GenServer.cast(__MODULE__, {:push, cdr})
  def get(), do: GenServer.call(__MODULE__, :pop)
  def start_link(stack), do: GenServer.start_link(__MODULE__, stack, name: __MODULE__)

  @impl true
  def init(stack) do
    IO.puts("NatsTestIex.CDR init #{Kernel.inspect(stack)}")
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, []) do
    IO.puts("NatsTestIex.CDR pop []")
    {:reply, [], []}
  end

  def handle_call(:pop, _from, [head | tail]) do
    IO.puts("NatsTestIex.CDR pop #{Kernel.inspect(head)} #{Kernel.inspect(tail)}")
    {:reply, [head], tail}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    IO.puts("NatsTestIex.CDR push #{Kernel.inspect(element)} #{Kernel.inspect(state)}")
    {:noreply, [element | state]}
  end
end
