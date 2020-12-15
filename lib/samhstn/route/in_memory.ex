defmodule Samhstn.Routes.InMemory do
  @moduledoc """
  In memory implementation for fetching routes data.
  We don't read from files or send http requests here.
  """
  use Samhstn.Route.Data

  def fetch_body(%Route.Ref{path: "vimrc"}) do
  end

  @spec get(RouteRef.t()) :: {:ok, RouteRef.t()} | {:error, RouteRef.error()}
  def get(%RouteRef{path: "vimrc"} = route_ref) do
    body = """
    syntax enable

    set number ignorecase smartcase incsearch autoindent
    """

    {:ok, %{route_ref |  body: body}}
  end

  def get(%{path: "dead_link"} = _route_ref) do
    {:error, "dead_link"}
  end
end
