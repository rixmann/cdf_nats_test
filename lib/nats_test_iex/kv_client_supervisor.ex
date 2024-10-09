defmodule NatsTestIex.KVClientSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_subscribers(number, req_per_sec \\ 100, extra_config \\ %{}) do
    old_childs = DynamicSupervisor.which_children(__MODULE__)

    case Enum.split(old_childs, number) do
      _ when number == 0 ->
        for {_, pid, _, _} <- old_childs, do: DynamicSupervisor.terminate_child(__MODULE__, pid)

      {keep, []} ->
        first_new = length(keep) + 1

        for i <- first_new..number do
          spec = {NatsTestIex.KVClient, %{id: i,
                                          attempts_per_second: req_per_sec} |> Map.merge(extra_config)}
          DynamicSupervisor.start_child(__MODULE__, spec)
        end

      {_, delete} ->
        for {_, pid, _, _} <- delete, do: DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
end
