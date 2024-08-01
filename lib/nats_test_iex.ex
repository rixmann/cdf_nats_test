defmodule NatsTestIex do
  @moduledoc """
  Documentation for `NatsTestIex`.
  """

  use Application

  alias Jetstream.API.{Consumer, Stream}

  def cdr_consumer_create(max_ack_pending) do
    consumer = %Jetstream.API.Consumer{
      stream_name: "CDR",
      durable_name: "CDR",
      ack_wait: 50_000_000_000,
      max_deliver: 200,
      max_ack_pending: max_ack_pending
    }

    Jetstream.API.Consumer.create(:gnat, consumer)
  end

  def cdr_consumer_delete() do
    Jetstream.API.Consumer.delete(:gnat, "CDR", "CDR")
  end

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
      NatsTestIex.QueueSupervisor,
      %{id: NatsTestIex.CDR, start: {NatsTestIex.CDR, :start_link, [[]]}}
    ]

    res = Supervisor.start_link(children, strategy: :one_for_one)
    :timer.sleep(100)
    create_stream_consumer()
    cdr_stream_consumer!()
    res
  end

  @doc """
  Setup NATS for our usecase.
  """
  def create_stream_consumer do
    stream = %Stream{
      name: "HELLO",
      subjects: ["greetings.*.*"],
      retention: :limits,
      discard: :old,
      max_bytes: 524_288_000
    }

    {:ok, _response} = Stream.create(:gnat, stream)

    consumer = %Consumer{
      stream_name: "HELLO",
      durable_name: "HELLO",
      ack_wait: 5_000_000_000,
      max_deliver: 200
    }

    {:ok, _response} = Consumer.create(:gnat, consumer)
  end

  @doc """
  Search for stream entries by "indexed" attributes

  ## Parameter `search_attrs`

  search_attrs is a map of index names and the value that we search for in the index.
  if an index is omitted a wildcard is used for its value.

  indexes are:
  * `:id` - uuid, should be unique among the subscribed topics
  * `:sequence` - integer, not unique
  """
  def search_in_archive(search_attrs) do
    id = Map.get(search_attrs, :id, "*")
    sequence = Map.get(search_attrs, :sequence, "*")

    Process.flag(:trap_exit, true)

    # setup consumer for searching the stream
    consumer = %Consumer{
      stream_name: "HELLO",
      durable_name: "SEARCHER",
      filter_subject: "greetings.#{id}.#{sequence}",
      ack_wait: 5_000_000_000
    }

    Consumer.create(:gnat, consumer)

    {:ok, consumer_pid} =
      Jetstream.PullConsumer.start_link(NatsTestIex.SearchingPullConsumer, [self(), id])

    # receive results
    receive do
      {:found_msg, msg} ->
        IO.puts(msg)
    after
      5000 ->
        IO.puts("nothing found after 5 seconds")
    end

    # gracefully tear down the consumer
    :ok = Jetstream.PullConsumer.close(consumer_pid)

    receive do
      {:EXIT, ^consumer_pid, :shutdown} ->
        nil
    end

    Consumer.delete(:gnat, "HELLO", "SEARCHER")
  end

  defp cdr_stream_consumer!() do
    stream = %Jetstream.API.Stream{
      name: "CDR",
      subjects: ["cdr"],
      retention: :limits,
      discard: :old,
      max_bytes: 524_288_000
    }

    {:ok, _} = Jetstream.API.Stream.create(:gnat, stream)

    # max_ack_pending default is 20000
    {:ok, _} = cdr_consumer_create(20_000)
  end
end
