defmodule Samhstn.Routes.Route do
  defstruct [:path, :type, :body]

  alias Samhstn.Routes.{Route, RouteRef}

  def get(%RouteRef{source: "url"} = route_ref) do
    case HTTPoison.get(route_ref.ref) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end

  def get(%RouteRef{source: "s3"} = route_ref) do
    "arn:aws:s3:::" <> rest = route_ref.ref

    [bucket, path] = String.split(rest, "/")

    body =
      ExAws.S3.download_file(bucket, path, :memory)
      |> ExAws.stream!()
      |> Enum.join()

    {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}
  end
end

