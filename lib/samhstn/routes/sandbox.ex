defmodule Samhstn.Routes.Sandbox do
  @moduledoc """
  Provides simple routing for urls according the content of priv/assets,
  behaves as if priv/assets was our s3 bucket.
  """
  alias Samhstn.Routes.{Route, RouteRef, InMemory}

  require Logger

  def init() do
    with path <- Path.join(File.cwd!(), "priv/assets/routes.json"),
         {:ok, json} <- File.read(path),
         {:ok, parsed} <- Jason.decode(json)
    do
      Enum.map(parsed, &RouteRef.from_map/1)
    else
      {:error, error} ->
        Logger.error(error)
        Logger.error("Problem reading routes.json")

        InMemory.init()
    end
  end

  def get(%RouteRef{source: "url"} = route_ref), do: Route.get(route_ref)

  def get(%RouteRef{source: "s3"} = route_ref) do
    with path <- Path.join(File.cwd!(), "priv/assets/") do
      Samhstn.Routes.Route.get(route_ref)
    end
  end
end
