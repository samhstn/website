import Config

config :samhstn, SamhstnWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  load_from_system_env: true,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info

config :samhstn, :routes, SamhstnWeb.Routes.Client
