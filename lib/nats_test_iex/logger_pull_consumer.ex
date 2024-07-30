defmodule NatsTestIex.LoggerPullConsumer do
  use Jetstream.PullConsumer

  def start_link([i]) do
    Jetstream.PullConsumer.start_link(__MODULE__, i, [])
  end

  @impl true
  def init(i) do
    {:ok, i, connection_name: :gnat, stream_name: "HELLO", consumer_name: "HELLO"}
  end

  @impl true
  def handle_message(_message, state) do
    # :timer.sleep(1000)
    # IO.puts("Pull Consumer #{state} got message: #{message.body} on topic #{message.topic}")
    {:ack, state}
  end
end
