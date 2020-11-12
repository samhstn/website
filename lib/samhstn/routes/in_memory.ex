defmodule Samhstn.Routes.InMemory do
  alias Samhstn.Routes.{Route, RouteRef}

  def init() do
    [
      %RouteRef{
        path: "vimrc",
        type: "text",
        source: "url",
        ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc"
      }
    ]
  end

  def get(%RouteRef{path: "vimrc"} = route_ref) do
    body = """
    syntax enable

    set number ignorecase smartcase incsearch autoindent
    """

    {:ok, %Route{path: "vimrc", type: route_ref.type, body: body}}
  end
end
