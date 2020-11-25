defmodule Samhstn.Routes.Sandbox do
  @moduledoc """
  Provides simple routing for urls according the content of priv/assets,
  behaves as if priv/assets was our s3 bucket.
  """
  alias Samhstn.Routes.{Route, RouteRef, InMemory, Client}

  require Logger

  @spec init() :: [RouteRef.t()]
  def init() do
    with path <- Path.join(File.cwd!(), "priv/assets/routes.json"),
         {:ok, json} <- File.read(path),
         {:ok, parsed} <- Jason.decode(json) do
      Enum.map(parsed, &RouteRef.from_map/1)
    else
      {:error, :enoent} ->
        Logger.error("routes.json file does not exist")

        InMemory.init()

      {:error, %Jason.DecodeError{} = error} ->
        Logger.error("Error parsing routes.json: #{Jason.DecodeError.message(error)}")

        InMemory.init()
    end
  end

  @spec get(RouteRef.t()) :: {:ok, Route.t()} | {:error, Route.error()}
  def get(%RouteRef{source: "url"} = route_ref), do: Client.get(route_ref)

  def get(%RouteRef{source: "s3"} = route_ref) do
    with %{object: object} <- Route.parse_s3_ref(route_ref.ref),
         {:ok, body} <- File.read(Path.join([File.cwd!(), "priv/assets", object])) do
      {:ok, %Route{body: body, path: route_ref.path, type: route_ref.type}}
    else
      {:error, :enoent} ->
        {:error, "file does not exist"}
    end
  end
end
