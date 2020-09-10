import Config

config :samhstn, SamhstnWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true

config :logger, :console, format: "[$level] $message\n"

# set higher stacktrace depth in dev for easier debugging
config :phoenix, :stacktrace_depth, 20

# initialize plugs at runtime for faster dev compilation
config :phoenix, :plug_init_mode, :runtime
