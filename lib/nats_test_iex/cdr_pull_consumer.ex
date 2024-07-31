defmodule NatsTestIex.CDRPullConsumer do
  use Jetstream.PullConsumer

  def start_link(config) do
    Jetstream.PullConsumer.start_link(__MODULE__, config, [])
  end

  @impl true
  def init(config) do
    IO.puts("CDRPullConsumer init #{Kernel.inspect(config)}")

    {:ok, Map.put(config, :nr, 0),
     connection_name: :gnat, stream_name: "CDR", consumer_name: "CDR"}
  end

  @impl true
  def handle_message(message, state) do
    # :timer.sleep(1000)
    body = message.body |> :erlang.binary_to_term() |> Kernel.inspect()
    IO.puts("CDRPullConsumer handle_message #{body} #{Kernel.inspect(state)}")
    NatsTestIex.CDR.arrived(message)
    {:noreply, new_state(state)}
  end

  #
  # Internal functions
  #

  defp new_state(state) do
    f = fn n -> n + 1 end
    Map.update!(state, :nr, f)
  end
end
