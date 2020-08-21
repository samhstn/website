defmodule SamhstnWeb.PageController do
  use SamhstnWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
