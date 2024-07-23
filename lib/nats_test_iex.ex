defmodule NatsTestIex do
  @moduledoc """
  Documentation for `NatsTestIex`.
  """

  use Application

  alias Jetstream.API.{Consumer,Stream}

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children = [
      {Gnat.ConnectionSupervisor,
       %{
         name: :gnat,
         connection_settings: [
           %{host: "localhost", port: 4222}
         ]
       }},
      NatsTestIex.QueueSupervisor
    ]
    res = Supervisor.start_link(children, strategy: :one_for_one)
    :timer.sleep(100)
    create_stream_consumer()
    res
  end

  @doc """
  Setup NATS for our usecase.
  """
  def create_stream_consumer do
    stream = %Stream{name: "HELLO", subjects: ["greetings.*"], retention: :limits, discard: :old, max_bytes: 1024}
    {:ok, _response} = Stream.create(:gnat, stream)
    consumer = %Consumer{stream_name: "HELLO", durable_name: "HELLO", ack_wait: 5_000_000_000, max_deliver: 200}
    {:ok, _response} = Consumer.create(:gnat, consumer)
  end

  def search_in_archive(id) do
    Process.flag(:trap_exit, true)
    consumer = %Consumer{stream_name: "HELLO", durable_name: "SEARCHER", filter_subject: "greetings.#{id}", ack_wait: 5_000_000_000}
    Consumer.create(:gnat, consumer)
    {:ok, consumer_pid} = Jetstream.PullConsumer.start_link(NatsTestIex.SearchingPullConsumer, [self(), id])
    receive do
      {:found_msg, msg} ->
        IO.puts(msg)
      ignored ->
        IO.inspect(ignored, label: "ignored message")
    after 5000 ->
        IO.puts("nothing found after 5 seconds")
    end
    :ok = Jetstream.PullConsumer.close(consumer_pid)
    receive do
      {:EXIT, consumer_pid, :shutdown} ->
        nil
    end
    Consumer.delete(:gnat, "HELLO", "SEARCHER")
  end
end
