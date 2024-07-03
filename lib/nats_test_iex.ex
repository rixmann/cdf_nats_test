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
      NatsTestIex.LoggerPullConsumer
    ]
    res = Supervisor.start_link(children, strategy: :one_for_one)
    hello()
    res
  end

  @doc """
  Hello world.

  ## Examples

      iex> NatsTestIex.hello()
      :world

  """
  def hello do
    stream = %Stream{name: "HELLO", subjects: ["greetings"]}
    {:ok, _response} = Stream.create(:gnat, stream)
    consumer = %Consumer{stream_name: "HELLO", durable_name: "HELLO", ack_wait: 5_000_000_000, max_deliver: 10}
    {:ok, _response} = Consumer.create(:gnat, consumer)
  end
end
