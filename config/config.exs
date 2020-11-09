import Config

config :phoenix, :json_library, Jason

config :samhstn, SamhstnWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: SamhstnWeb.ErrorView, accepts: ["html", "json"], layout: false]

import_config "#{Mix.env()}.exs"
