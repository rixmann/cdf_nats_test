defmodule NatsTestIex.CDRPullConsumer do
  use Jetstream.PullConsumer

  def start_link(_) do
    Jetstream.PullConsumer.start_link(__MODULE__, %{}, [])
  end

  @impl true
  def init(state) do
    {:ok, state, connection_name: :gnat, stream_name: "CDR", consumer_name: "CDR"}
  end

  @impl true
  def handle_message(message, state) do
    # :timer.sleep(1000)
    IO.puts(
      "#{Kernel.inspect(state)} body: #{Kernel.inspect(message.body)} topic: #{Kernel.inspect(message.topic)}"
    )

    message.body |> :erlang.binary_to_term() |> NatsTestIex.CDR.arrived()
    {:ack, state}
  end
end
