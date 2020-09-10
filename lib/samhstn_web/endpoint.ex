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
      port = System.fetch_env!("PORT")
      cert_dir = System.fetch_env!("CERT_DIR")
      secret_key_base = System.fetch_env!("SECRET_KEY_BASE")

      url = [
        scheme: "https",
        host: "localhost",
        port: port
      ]

      https = [
        port: port,
        keyfile: "#{cert_dir}/key.pem",
        certfile: "#{cert_dir}/cert.pem"
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
