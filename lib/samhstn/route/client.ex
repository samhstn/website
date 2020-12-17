defmodule Samhstn.Route.Client do
  @moduledoc """
  Provides routing for urls and content in s3 buckets,
  routes according to content of `routes.json` in our "assets" bucket.
  """
  use Samhstn.Route.Data

  @spec fetch_body(Route.Ref.t()) :: {:ok, String.t()} | {:error, String.t()}
  def fetch_body(%Route.Ref{source: :url} = route_ref) do
    case HTTPoison.get(route_ref.ref) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, body}

      {:error, error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end

  def fetch_body(%Route.Ref{source: :s3} = route_ref) do
    %{bucket: bucket, object: object} = Route.Ref.parse_s3_ref(route_ref.ref)

    body =
      ExAws.S3.download_file(bucket, object, :memory)
      |> ExAws.stream!()
      |> Enum.join()

    {:ok, body: body}
  end
end
