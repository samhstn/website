defmodule Samhstn.Routes.InMemory do
  @moduledoc """
  In memory implementation for fetching routes data.
  We don't read from files or send http requests here.
  """
  alias Samhstn.Routes.{Route, RouteRef}

  @spec init() :: [RouteRef.t()]
  def init() do
    [
      %RouteRef{
        path: "vimrc",
        type: :text,
        source: "url",
        ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc"
      }
    ]
  end

  @spec get(RouteRef.t()) :: {:ok, Route.t()} | {:error, Route.error()}
  def get(%RouteRef{path: "vimrc"} = route_ref) do
    body = """
    syntax enable

    set number ignorecase smartcase incsearch autoindent
    """

    {:ok, %Route{path: "vimrc", type: route_ref.type, body: body}}
  end

  def get(%RouteRef{path: "dead_link"} = _route_ref) do
    {:error, "dead_link"}
  end
end
