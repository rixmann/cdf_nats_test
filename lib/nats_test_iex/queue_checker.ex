defmodule NatsTestIex.QueueChecker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send_some_messages(some, start_at \\ 1) do
    # :ok = reset_state()
    for i <- start_at..(start_at + some) do
      # :ok = Gnat.pub(:gnat, "greetings.#{UUID.uuid4()}.#{i}", "Hello World #{i}")
      {:ok, res} = Gnat.request(:gnat, "greetings", "Hello World #{i}")
      {:ok, res_map} = Jason.decode(res.body)
      if ["seq", "stream"] != res_map |> Map.keys() do
        IO.inspect(res_map, label: "bad result from publishing")
      end
    end
  end

  def get_state(), do: GenServer.call(__MODULE__, :get_state)

  def received(id), do: GenServer.call(__MODULE__, {:received, id})

  def reset_state(min \\ 1), do: GenServer.cast(__MODULE__, {:reset_state, min})

  def init(_) do
    {:ok, %{min: 1, outstanding_updates: []}}
  end

  def handle_cast({:reset_state, min}, state) do
    {:noreply, %{min: min, outstanding_updates: []}}
  end

  def handle_call({:received, id}, _from, state) do
    # IO.puts("received id: #{id}")
    # IO.inspect(state)
    int_id = id |> String.to_integer

    new_state = received(int_id, state.min, state.outstanding_updates)

    {:reply, :ok, new_state}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def received(id, id,  outstanding), do: clean_outstanding(id + 1,  outstanding)
  def received(id, min,  outstanding), do: %{min: min, outstanding_updates: outstanding ++ [id]}

  def clean_outstanding(min, outstanding) do
    {mi, nouts} = Enum.reduce(outstanding, {min, []},
      fn(mi, {mi, new_outstanding}) ->
        {mi + 1, new_outstanding}
        (received_before, {mi, new_outstanding}) ->
          {mi, new_outstanding ++ [received_before]}
      end)
    if mi == min and nouts == outstanding do
      %{min: mi, outstanding_updates: nouts}
    else
      clean_outstanding(mi, nouts)
    end
  end
end
