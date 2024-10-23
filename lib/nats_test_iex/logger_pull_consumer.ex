defmodule NatsTestIex.LoggerPullConsumer do
  use Jetstream.PullConsumer

  def start_link([i]) do
    Jetstream.PullConsumer.start_link(__MODULE__, i, [])
  end

  @impl true
  def init(i) do
    connection = "gnat-#{i}" |> String.to_atom
    {:ok, i, connection_name: connection, stream_name: "HELLO", consumer_name: "HELLO"}
  end

  @impl true
  def handle_message(message, state) do
    # :timer.sleep(1000)
    # IO.puts("Pull Consumer #{state} got message: #{message.body} on topic #{message.topic}")
    fetch_message_id(message)
    {:ack, state}
  end

  def fetch_message_id(message) do
    case Regex.run(~r{(\d*$)}, message.body, capture: :first) do
      [result] ->
        NatsTestIex.QueueChecker.received(result)
      _ ->
        IO.puts("Consumer got message that doesn't match the pattern: #{message.body}")
    end
  end
end
