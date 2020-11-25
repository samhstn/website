defmodule Samhstn.Routes.Client do
  @moduledoc """
  Provides routing for urls and content in s3 buckets,
  routes according to content of `routes.json` in our "assets" bucket.
  """
  alias Samhstn.Routes.{Route, RouteRef}

  @spec init() :: [RouteRef.t()]
  def init() do
    "samhstn-assets-741557730458"
    |> ExAws.S3.download_file("routes.json", :memory)
    |> ExAws.stream!()
    |> Enum.join()
    |> Jason.decode!()
    |> Enum.map(&RouteRef.from_map/1)
  end

  @spec get(RouteRef.t()) :: {:ok, Route.t()} | {:error, Route.error()}
  def get(%RouteRef{source: "url"} = route_ref) do
    case HTTPoison.get(route_ref.ref) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}

      {:error, error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end

  def get(%RouteRef{source: "s3"} = route_ref) do
    %{bucket: bucket, object: object} = Route.parse_s3_ref(route_ref.ref)

    body =
      ExAws.S3.download_file(bucket, object, :memory)
      |> ExAws.stream!()
      |> Enum.join()

    {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}
  end
end
