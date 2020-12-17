import Config

config :samhstn, SamhstnWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

config :samhstn, :route, Samhstn.Route.InMemory

config :samhstn, :route_backoff,
  min: 50,
  max: 1000,
  multiplier: 2

config :samhstn, :children, [SamhstnWeb.Endpoint]
