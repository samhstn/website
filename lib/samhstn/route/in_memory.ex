defmodule Samhstn.Routes.InMemory do
  @moduledoc """
  In memory implementation for fetching routes data.
  We don't read from files or send http requests here.
  """
  alias Samhstn.Routes.RouteRef

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
