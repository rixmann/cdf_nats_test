defmodule NatsTestIex.CDRPullConsumer do
  use Jetstream.PullConsumer

  def start_link(config) do
    Jetstream.PullConsumer.start_link(__MODULE__, config, [])
  end

  @impl true
  def init(config) do
    IO.puts("NatsTestIex.CDRPullConsumer init #{Kernel.inspect(config)}")

    {:ok, Map.put(config, :nr, 0),
     connection_name: :gnat, stream_name: "CDR", consumer_name: "CDR"}
  end

  @impl true
  def handle_message(message, state) do
    # :timer.sleep(1000)
    term = message.body |> :erlang.binary_to_term()

    IO.puts(
      "NatsTestIex.CDRPullConsumer handle_message #{Kernel.inspect(state)} #{Kernel.inspect(term)}"
    )

    NatsTestIex.CDR.arrived(term)
    {:ack, new_state(state)}
  end

  #
  # Internal functions
  #

  defp new_state(state) do
    f = fn n -> n + 1 end
    Map.update!(state, :nr, f)
  end
end
