defmodule SamhstnWeb.PageController do
  use SamhstnWeb, :controller

  alias Samhstn.Routes.Route

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec routes(Plug.Conn.t(), map) :: Plug.Conn.t()
  # marked as a false positive as we trust the
  # html data coming through from our routes.json file.
  # sobelow_skip ["XSS.HTML"]
  def routes(conn, %{"path" => path}) do
    case Samhstn.Routes.get(path) do
      {:ok, %Route{type: :json, body: body}} ->
        json(conn, body)

      {:ok, %Route{type: :text, body: body}} ->
        text(conn, body)

      {:ok, %Route{type: :html, body: body}} ->
        html(conn, body)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(SamhstnWeb.ErrorView)
        |> render("404.html")

      {:error, _error} ->
        conn
        |> put_status(500)
        |> put_view(SamhstnWeb.ErrorView)
        |> render("500.html")
    end
  end
end
