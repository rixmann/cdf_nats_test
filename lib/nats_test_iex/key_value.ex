defmodule NatsTestIex.KeyValue do

  @bucket "my-bucket"

  def provision(extra_params \\ []) do
    params = [max_bucket_size: extra_params[:max_bucket_size] || 1_000_000] ++ Keyword.delete(extra_params, :max_bucket_size)
    bucket = extra_params[:bucket] |> get_bucket()
    Gnat.Jetstream.API.KV.create_bucket(:gnat, bucket, params)
  end

  def deprovision(bucket \\ nil) do
    Gnat.Jetstream.API.KV.delete_bucket(:gnat, get_bucket(bucket))
  end

  def insert(key_size, value_size, bucket \\ nil) do
    key = random_string(key_size)
    value = random_string(value_size)
    case Gnat.Jetstream.API.KV.create_key(get_random_pool_connection(), get_bucket(bucket), key, value) do
      :ok ->
        {key, value}
      {:error, reason} ->
        IO.puts("error inserting key/value pair: #{inspect reason}")
        nil
    end
  end

  def read(key, bucket \\ nil) do
    Gnat.Jetstream.API.KV.get_value(get_random_pool_connection(), get_bucket(bucket), key)
  end

  def delete(key, bucket \\ nil) do
    Gnat.Jetstream.API.KV.delete_key(get_random_pool_connection(), get_bucket(bucket), key)
    #    :ok = Gnat.Jetstream.API.KV.purge_key(get_random_pool_connection(), @bucket, key)
  end

  def info(bucket \\ nil) do
    Gnat.Jetstream.API.Stream.info(:gnat, Gnat.Jetstream.API.KV.stream_name(get_bucket(bucket)))
  end

  defp get_bucket(nil), do: @bucket
  defp get_bucket(name), do: name

  defp random_string(size) do
    Base.encode64(:crypto.strong_rand_bytes(size))
  end

  def get_random_pool_connection() do
    pool_size = (:os.getenv('NATS_POOL_SIZE') || '10') |> to_string |> String.to_integer
    selected = Enum.random(1..pool_size)
    "gnat-#{selected}" |> String.to_atom
  end
end
