defmodule NatsTestIex.SearchingPullConsumer do
  use Jetstream.PullConsumer

  def start_link(args) do
    Jetstream.PullConsumer.start_link(__MODULE__, args, [])
  end

  @impl true
  def init(args) do
    {:ok, args, connection_name: :gnat, stream_name: "HELLO", consumer_name: "SEARCHER"}
  end

  @impl true
  def handle_message(message, [reply_to, id] = state) do
    send(reply_to, {:found_msg, "Found event for id #{id} got message: #{message.body} on topic #{message.topic}"})
    {:ack, state}
  end
end
