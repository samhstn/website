defmodule Samhstn.Route.Data do
  @moduledoc """
  Defines a struct and the required functions for fetching our route data.
  These functions have different implementations depending on environment, but the same behaviour.
  """
  @enforce_keys [:body, :updated_at, :requested_at, :next_update_seconds, :reference]
  defstruct [:body, :updated_at, :requested_at, :next_update_seconds, :reference]

  alias Samhstn.Route

  @type t() :: %__MODULE__{
    body: String.t(),
    updated_at: NaiveDateTime.t(),
    requested_at: NaiveDateTime.t(),
    next_update_seconds: integer,
    reference: reference
  }

  @doc """
  Fetches the body for a given route ref.
  """
  @callback fetch(Route.Ref.t()) :: String.t()

  @doc """
  Returns data relating to our routes.json file
  and generates a list of route references.
  """
  @spec init() :: Route.state()
  def init() do
    routes_data = %Route.Data{body: json} = get_routes_data!()
    routes = json |> Jason.decode!() |> Enum.map(&Route.Ref.from_map/1)

    {routes_data, routes}
  end

  @doc """
  Populates :data in our route ref.
  """
  @spec get(Route.Ref.t()) :: {:ok, Route.Ref.t()} | {:error, Route.Ref.error()}
  def get(route_ref = Route.Ref{}) do
    route_ref
    |> fetch()
    |> 
  end

  @spec get!(Route.Ref.t()) :: Route.Ref.t()
  def get!(route_ref = %Route.Ref{}) do
    case get(route_ref) do
      {:ok, route_ref} ->
        route_ref

      {:error, error} ->
        throw error
    end
  end

  @doc """
  Updates the given route ref in our list of routes and re-schedules our route ref timer.
  """
  @spec new_routes(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
  def new_routes(new_route_ref, routes) do
    # TODO: implement
    routes
  end

  @spec get_new_routes!(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
  def get_new_routes!(route_ref, routes) do
    route_ref
    |> get!()
    |> new_routes(routes)
  end

  @spec get_new_routes_data_and_routes!(Route.Ref.t(), [Route.Ref.t()]) :: Route.state()
  def get_new_routes_data_and_routes!(routes_data, routes) do
    get_json(routes_data)
  end

  @spec check_new_routes(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
  def check_new_routes!(route_ref, routes) do
    route_ref
    |> check!()
    |> new_routes()
  end

  defmacro __using__(_) do
    quote do
      alias Samhstn.Route

      # This @behaviour throws a warning if fetch/1 isn't defined in the module where this is used.
      @behaviour Route.Data

      defdelegate init(), to: Route.Data.init
      defdelegate new_routes(routes, new_route_ref), to: Route.Data.new_routes
      defdelegate get_new_routes!(routes, new_route_ref), to: Route.Data.new_routes
      defdelegate get_new_routes_data_and_routes!(routes_data, routes), to: Route.Data.get_new_routes_data_and_routes!
      defdelegate check_new_routes!(routes, new_route_ref), to: Route.Data.check_new_routes!
      defdelegate check_new_routes_data_and_routes!(routes_data, routes), to: Route.Data.check_new_routes_data_and_routes!
    end
  end
end
