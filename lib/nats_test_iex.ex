defmodule NatsTestIex do
  @moduledoc """
  Documentation for `NatsTestIex`.
  """

  use Application

  def topic(i), do: "foo.#{i}"

  def subscribe_start_loop(gnat, i) do
    {:ok, subscription} = Gnat.sub(gnat, self(), topic(i))
    loop_receive_forward(gnat, i)
  end

  def loop_receive_forward(gnat, i, print_last \\ false) do
    receive do
      {:msg, %{body: body, topic: _, reply_to: nil}} ->
        if print_last do
          IO.puts(body)
        else
          :ok = Gnat.pub(gnat, topic(i + 1), body)
        end
        loop_receive_forward(gnat, i, print_last)
      other ->
        IO.inspect(other, label: "error error error: ")
    end
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    {:ok, gnat} = Gnat.start_link(%{host: '127.0.0.1', port: 4222, tls: false})
    chain_length = 3000
    for i <- 1..chain_length do
      Process.spawn(fn() ->
        subscribe_start_loop(gnat, i)
      end, [:link])
    end

    Process.spawn(fn() ->
      {:ok, subscription} = Gnat.sub(gnat, self(), topic(chain_length + 1))
      loop_receive_forward(gnat, chain_length + 1, true)
    end, [:link])

    :timer.sleep(100)

    IO.puts "publishing now"
    for i <- 1..10 do
      :ok = Gnat.pub(gnat, topic(1), "Hello #{i}")
      :timer.sleep(1000)
    end

    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Hello world.

  ## Examples

      iex> NatsTestIex.hello()
      :world

  """
  def hello do
    :world
  end
end
