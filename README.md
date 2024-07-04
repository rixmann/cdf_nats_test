# NatsTestIex

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nats_test_iex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nats_test_iex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/nats_test_iex>.


## start nats dockered

`docker run -p 4222:4222 nats -js`

## perform test

```elixir
$ iex -S mix run
iex(1)> NatsTestIex.QueueSupervisor.start_subscribers(3)
[ok: #PID<0.261.0>, ok: #PID<0.262.0>, ok: #PID<0.263.0>]

iex(2)> for i <- 1..1, do: Gnat.pub(:gnat, "greetings", "Hello World #{i}")
[:ok]
```
