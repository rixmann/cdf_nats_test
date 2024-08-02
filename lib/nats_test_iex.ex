defmodule NatsTestIex do
  @moduledoc """
  Documentation for `NatsTestIex`.
  """

  use Application

  alias Jetstream.API.{Consumer, Stream}

  @spec cdr_consumer_create(non_neg_integer()) :: {:ok, map()} | {:error, map()}
  def cdr_consumer_create(max_ack_pending) do
    consumer = %{
      stream_name: "CDR",
      durable_name: "CDR",
      ack_wait: 50_000_000_000,
      max_deliver: 200,
      #      deliver_policy: :new,
      max_ack_pending: max_ack_pending
    }

    Jetstream.API.Consumer.info(:gnat, consumer.stream_name, consumer.durable_name)
    |> cdr_consumer_correct(consumer)
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

  defp cdr_consumer_correct({:ok, info}, config) do
    config_keys = Map.keys(config)
    f = fn value -> value end

    Map.take(info.config, config_keys)
    |> Map.update(:stream_name, config.stream_name, f)
    |> cdr_consumer_correct_config(config)
  end

  defp cdr_consumer_correct({:error, _error}, config) do
    IO.puts("CDR consumer create")
    consumer = Kernel.struct(Jetstream.API.Consumer, config)
    Jetstream.API.Consumer.create(:gnat, consumer)
  end

  defp cdr_consumer_correct_config(config, config), do: {:ok, %{config: config}}

  defp cdr_consumer_correct_config(old, config) do
    IO.puts("CDR consumer delete old")
    IO.inspect(old)
    Jetstream.API.Consumer.delete(:gnat, old.stream_name, old.durable_name)
    IO.puts("CDR consumer create")
    IO.inspect(config)
    consumer = Kernel.struct(Jetstream.API.Consumer, config)
    Jetstream.API.Consumer.create(:gnat, consumer)
  end

  defp cdr_stream_consumer!() do
    stream = %{
      name: "CDR",
      subjects: ["one_cdr"],
      retention: :limits,
      discard: :old,
      max_bytes: 524_288_000
    }

    :ok = Jetstream.API.Stream.info(:gnat, stream.name) |> cdr_stream_correct(stream)

    # max_ack_pending default is 20000
    {:ok, _} = cdr_consumer_create(20_000)
  end

  defp cdr_stream_correct({:ok, info}, config) do
    config_keys = Map.keys(config)
    Map.take(info.config, config_keys) |> cdr_stream_correct_config(config)
  end

  defp cdr_stream_correct({:error, _error}, config) do
    IO.puts("CDR stream create")
    stream = Kernel.struct(Jetstream.API.Stream, config)
    Jetstream.API.Stream.create(:gnat, stream) |> Kernel.elem(0)
  end

  defp cdr_stream_correct_config(config, config), do: :ok

  defp cdr_stream_correct_config(old, config) do
    IO.puts("CDR stream delete old")
    Jetstream.API.Stream.delete(:gnat, old.name)
    IO.puts("CDR stream create")
    stream = Kernel.struct(Jetstream.API.Stream, config)
    Jetstream.API.Stream.create(:gnat, stream) |> Kernel.elem(0)
  end
end
