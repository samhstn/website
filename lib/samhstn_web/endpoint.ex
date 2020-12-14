defmodule SamhstnWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :samhstn

  @session_options [
    store: :cookie,
    key: "_samhstn_key",
    signing_salt: "aaD4//C4"
  ]

  plug Plug.Static,
    at: "/static",
    from: "priv/static",
    gzip: Mix.env() == :prod

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug SamhstnWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = Application.fetch_env!(:samhstn, :port)
      host = Application.fetch_env!(:samhstn, :host)
      secret_key_base = Application.fetch_env!(:samhstn, :secret_key_base)

      url = [
        scheme: "https",
        host: host,
        port: port
      ]

      https = [
        port: port,
        keyfile: "../../../../../../priv/keys/key.pem",
        certfile: "../../../../../../priv/keys/cert.pem"
      ]

      config =
        config
        |> Keyword.put(:url, url)
        |> Keyword.put(:https, https)
        |> Keyword.put(:secret_key_base, secret_key_base)

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
