defmodule NatsTestIex.KVClient do
  use GenServer

  @default_attempts_per_second 100
  @default_key_size 10
  @default_value_size 1800

  def start_link(state) do
    attempts_per_second = state[:attempts_per_second] || @default_attempts_per_second
    inserted = for _ <- 1..attempts_per_second, do: nil
    state = %{
      id: state[:id],
      attempts_per_second: attempts_per_second,
      inserted: inserted,
      key_size: state[:key_size] || @default_key_size,
      value_size: state[:value_size] || @default_value_size,
      bucket: state[:bucket]
    }
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(i) do
    send(self(), {:do_something, 0, time_now() })
    {:ok, i}
  end

  @impl true
  def handle_info({:do_something, already_done, since}, state = %{attempts_per_second: to_do}) when already_done < to_do do
    fresh_inserted = insert_kv(state)
    state = delete_oldest(state)

    send(self(), {:do_something, already_done + 1, since})
    {:noreply, state |> Map.put(:inserted, [fresh_inserted | state.inserted])}
  end
  def handle_info({:do_something, already_done, since}, state = %{attempts_per_second: to_do}) when already_done == to_do do
    case (time_now() - since) do
      i when 0 < i and i < 1000 ->
        IO.puts("#{state.id} about to roll over, left: #{1000 - i}ms")
        :timer.send_after(1000 - i, self(), {:do_something, already_done, since} )
        {:noreply, state}
      time_it_took ->
        IO.puts("#{state.id} rolling over after #{time_it_took}ms")
        send(self(), {:do_something, 0, time_now()})
        {:noreply, state}
    end
  end
  def handle_info(message, state) do
    IO.inspect(message, label: "KVClient #{inspect state} got message")
    {:noreply, state}
  end

  def insert_kv(%{key_size: key_size, value_size: value_size} = state) do
    NatsTestIex.KeyValue.insert(key_size, value_size, state[:bucket])
  end

  def time_now(), do: :erlang.system_time(:millisecond)

  def delete_oldest(state = %{inserted: inserted}) do
    {to_delete, leftovers} = List.pop_at(inserted, -1)
    case to_delete do
      nil ->
        :ok
      {k, v} ->
        case NatsTestIex.KeyValue.read(k, state[:bucket]) do
          ^v ->
            case NatsTestIex.KeyValue.delete(k, state[:bucket]) do
              :ok ->
                nil
              other ->
                IO.puts("error deleting key #{inspect k}: #{inspect other}")
            end
          other ->
            IO.puts("error reading key #{inspect k}: #{inspect other}")
        end
    end
    Map.put(state, :inserted, leftovers)
  end
end
