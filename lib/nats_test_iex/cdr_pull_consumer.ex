defmodule NatsTestIex.CDRPullConsumer do
  use Jetstream.PullConsumer

  def start_link(_) do
    Jetstream.PullConsumer.start_link(__MODULE__, %{}, [])
  end

  @impl true
  def init(state) do
    {:ok, Map.put(state, :nr, 0),
     connection_name: :gnat, stream_name: "CDR", consumer_name: "CDR"}
  end

  @impl true
  def handle_message(message, state) do
    # :timer.sleep(1000)
    term = message.body |> :erlang.binary_to_term()
    IO.puts("NatsTestIex.CDRPullConsumer #{Kernel.inspect(state)} #{Kernel.inspect(term)}")
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
