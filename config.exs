use Mix.Config

config :phoenix, :json_library, Jason

config :samhstn, SamhstnWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: SamhstnWeb.ErrorView, accepts: ["html", "json"], layout: false]

case Mix.env() do
  :test ->
    config :samhstn, SamhstnWeb.Endpoint,
      http: [port: 4002],
      server: false

    config :logger, level: :warn

  :dev ->
    config :samhstn, SamhstnWeb.Endpoint,
      http: [port: 4000],
      debug_errors: true

    config :logger, :console, format: "[$level] $message\n"

    # set higher stacktrace depth in dev for easier debugging
    config :phoenix, :stacktrace_depth, 20

    # initialize plugs at runtime for faster dev compilation
    config :phoenix, :plug_init_mode, :runtime

  :prod ->
    config :samhstn, SamhstnWeb.Endpoint,
      force_ssl: [rewrite_on: [:x_forwarded_proto]],
      load_from_system_env: true,
      server: true

    config :logger, level: :info
end
