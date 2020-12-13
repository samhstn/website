import Config

config :samhstn, SamhstnWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

config :samhstn, :route, Samhstn.Route.InMemory

config :samhstn, :children, [SamhstnWeb.Endpoint]
