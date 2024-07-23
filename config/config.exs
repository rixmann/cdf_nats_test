import Config

# Configures Elixir's Logger
config :logger,
  level: :error


try do
  import_config "#{Mix.env()}.exs"
rescue
  _ in _ ->
    :skip
end
