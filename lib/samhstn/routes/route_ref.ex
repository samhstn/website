defmodule Samhstn.Routes.RouteRef do
  @enforce_keys [:path, :type, :source, :ref]
  defstruct [:path, :type, :source, :ref, :data]

  alias Samhstn.Routes.{Route, RouteRef}
  alias Samhstn.Routes.RouteRef.Data

  @type source() :: :s3 | :url
  @type t() :: %__MODULE__{
          data: Data.t(),
          path: String.t(),
          ref: String.t(),
          source: source,
          type: Route.type()
        }

  @spec type_to_atom(String.t()) :: Route.type()
  defp type_to_atom("html"), do: :html
  defp type_to_atom("json"), do: :json
  defp type_to_atom("text"), do: :text

  defp source_to_atom(String.t()) :: source
  defp source_to_atom("s3"), do: :s3
  defp source_to_atom("url"), do: :url

  @spec from_map(map) :: RouteRef.t()
  def from_map(%{"path" => path, "type" => type, "source" => source, "ref" => ref}) do
    %RouteRef{
      path: path,
      type: type_to_atom(type),
      source: source_to_atom(source),
      ref: ref
    }
  end

  @spec parse_s3_ref(String.t() | {String.t(), String.t()}) :: map
  def parse_s3_ref("arn:aws:s3:::" <> rest) do
    [bucket | path] = String.split(rest, "/")

    %{bucket: bucket, object: Enum.join(path, "/")}
  end

  def parse_s3_ref({bucket, object}) do
    %{bucket: bucket, object: object}
  end

  @spec clear_data(RouteRef.t()) :: RouteRef.t()
  def clear_data(route_ref), do: Map.delete(route_ref, :data)

  @spec route(RouteRef.t()) :: Route.t()
  def to_route(%RouteRef{type: type, data: %Data{body: body}}) do
    %Route{body: body, type: type}
  end
end

defmodule Samhstn.Routes.Route do
  @enforce_keys [:type, :body]
  defstruct [:type, :body]

  @type type() :: :html | :json | :text
  @type error() :: String.t()
  @type t() :: %__MODULE__{
    type: type,
    body: String.t()
  }
end

defmodule Samhstn.Routes.RouteRef.Data do
  @enforce_keys [:body, :updated_at, :requested_at, :next_update_seconds, :reference]
  defstruct [:body, :updated_at, :requested_at, :next_update_seconds, :reference]

  alias Samhstn.Routes

  @type t() :: %__MODULE__{
    body: String.t(),
    updated_at: NaiveDateTime.t(),
    requested_at: NaiveDateTime.t(),
    next_update_seconds: pos_integer(),
    reference: reference
  }

  @routes Application.get_env(:samhstn, :routes)

  @doc """
  Updates all necessary routes.
  Configures the frequency of the updates schedule based on the last time routes were visited.
  """
  @spec get_new_cache(Routes.cache) :: Routes.cache
  def update(cache) do
    cache
    |> Task.async_stream(fn {user_requested_at, last_updated_at, route} = route_cache ->
      cond do
        NaiveDateTime.compare(user_requested_at, last_updated_at) == :gt ->
          route
          |> @routes.get()
          |> case do
            {:ok, r} ->
              now = NaiveDateTime.utc_now()
              {user_requested_at, now, r}

            {:error, error} ->
              Logger.error("Could not find route from RouteRef", error)
              route_cache
          end
      end
    end)
    |> Enum.map(fn {:ok, route_cache} -> route_cache end)
  end

  @spec update_frequency(Routes.cache) :: Routes.cache_update_frequency
  def update_frequency([]), do: :none
  def update_frequency(cache) do
    []
  end
end
