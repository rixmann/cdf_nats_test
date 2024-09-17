defmodule NatsTestIex.KeyValue do

  @bucket "my-bucket"

  def provision() do
    Gnat.Jetstream.API.KV.create_bucket(:gnat, @bucket, max_bucket_size: 1_000_000)
  end

  def deprovision() do
    Gnat.Jetstream.API.KV.delete_bucket(:gnat, @bucket)
  end

  def insert() do
    key = random_string()
    value = random_string()
    :ok = Gnat.Jetstream.API.KV.create_key(get_random_pool_connection(), @bucket, key, value)
    {key, value}
  end

  def read(key) do
    Gnat.Jetstream.API.KV.get_value(get_random_pool_connection(), @bucket, key)
  end

  def delete(key) do
    :ok = Gnat.Jetstream.API.KV.delete_key(get_random_pool_connection(), @bucket, key)
#     :ok = Gnat.Jetstream.API.KV.purge_key(get_random_pool_connection(), @bucket, key)
  end

  def info() do
    Gnat.Jetstream.API.Stream.info(:gnat, Gnat.Jetstream.API.KV.stream_name(@bucket))
  end

  defp random_string() do
    for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')>>
  end

  def get_random_pool_connection() do
    pool_size = (:os.getenv('NATS_POOL_SIZE') || '10') |> to_string |> String.to_integer
    selected = Enum.random(1..pool_size)
    "gnat-#{selected}" |> String.to_atom
  end
end
