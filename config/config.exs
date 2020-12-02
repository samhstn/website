import Config

config :phoenix, :json_library, Jason

config :samhstn, SamhstnWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: SamhstnWeb.ErrorView, accepts: ["html", "json"], layout: false]

config :samhstn, :children, [SamhstnWeb.Endpoint, Samhstn.Routes]

import_config "#{Mix.env()}.exs"
