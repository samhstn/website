defmodule Samhstn.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [SamhstnWeb.Endpoint, SamhstnWeb.Routes],
      [strategy: :one_for_one, name: Samhstn.Supervisor]
    )
  end
end
