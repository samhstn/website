defmodule Samhstn.Routes.Client do
  @moduledoc """
  Provides routing for urls and content in s3 buckets,
  routes according to content of `routes.json` in our "assets" bucket.
  """
  alias Samhstn.Routes.{Route, RouteRef}

  def init() do
    "samhstn-assets-741557730458"
    |> ExAws.S3.download_file("routes.json", :memory)
    |> ExAws.stream!()
    |> Enum.join()
    |> Jason.decode!()
    |> Enum.map(&RouteRef.from_map/1)
  end

  defdelegate get(route_ref), to: Route
end
