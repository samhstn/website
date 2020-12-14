defmodule Samhstn.Routes.Client do
  @moduledoc """
  Provides routing for urls and content in s3 buckets,
  routes according to content of `routes.json` in our "assets" bucket.
  """
  alias Samhstn.Routes.RouteRef

  @spec init() :: [RouteRef.t()]
  def init() do
    %RouteRef{
      path: "routes.json",
      ref: {Application.fetch_env!(:samhstn, :assets_bucket), "routes.json"},
      source: :s3,
      type: :json
    }
    |> source_and_cache!()
    |> Map.get(:body)
    |> Jason.decode!()
    |> Enum.map(&RouteRef.from_map/1)


  end

  @spec source_and_cache(RouteRef.t()) :: {:ok, RouteRef.t()} | {:error, RouteRef.error()}
  def source_and_cache(%RouteRef{source: :url} = route_ref) do
    case HTTPoison.get(route_ref.ref) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %{route_ref | body: body}}

      {:error, error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end

  def source_and_cache(%RouteRef{source: :s3} = route_ref) do
    %{bucket: bucket, object: object} = RouteRef.parse_s3_ref(route_ref.ref)

    body =
      ExAws.S3.download_file(bucket, object, :memory)
      |> ExAws.stream!()
      |> Enum.join()

    {:ok, %{route_ref | body: body}}
  end

  @spec source_and_cache!(RouteRef.t()) :: RouteRef.t()
  def source_and_cache!(%RouteRef{} = route_ref) do0
    case get(route_ref) do
      {:ok, rr} ->
        rr

      {:error, error} ->
        throw error
    end
  end
end
