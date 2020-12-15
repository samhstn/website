defmodule Samhstn.Route.Data do
  @moduledoc """
  Defines a struct and the required functions for fetching our route data.
  These functions have different implementations depending on environment, but the same behaviour.
  """
  @enforce_keys [:body, :updated_at, :requested_at, :next_update_seconds, :timer]
  defstruct [:body, :updated_at, :requested_at, :next_update_seconds, :timer]

  alias Samhstn.Route

  @type t() :: %__MODULE__{
    body: String.t(),
    updated_at: NaiveDateTime.t(),
    requested_at: NaiveDateTime.t(),
    next_update_seconds: integer,
    timer: reference
  }

  @backoff Application.fetch_env!(:samhstn, :route_backoff)

  @doc """
  Fetches the body for a given route ref.

  This function needs to be defined where this module macro is used.
  """
  @callback fetch_body(Route.Ref.t()) :: {:ok, String.t()} | {:error, Route.Ref.error()}

  @doc """
  Returns the environment dependent reference for our routes data.

  This function needs to be defined where this module macro is used.
  """
  @callback routes_data_ref() :: Route.Ref.ref()

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
  Populates the :data field in our route ref.
  """
  @spec get(Route.Ref.t()) :: {:ok, Route.Ref.t()} | {:error, Route.Ref.error()}
  def get(%Route.Ref{path: path} = route_ref) do
    new_body = fetch_body(route_ref)
    now = NaiveDateTime.utc_now()
    min = @backoff[:min]

    cond do
      is_nil(route_ref[:data]) ->
        timer = Route.schedule_check(path, min)
        data = %Route.Data{
          body: new_body,
          updated_at: now,
          requested_at: now,
          next_update_seconds: min,
          timer: timer
        }

        %{route_ref | data: data}

      route_ref[:data][:body] == new_body ->
        route_ref

      route_ref[:data][:body] != new_body ->
        route_ref
    end
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
  Fetches the routes data and schedules route updates.
  """
  @spec get_routes_data!() :: Route.Data.t()
  def get_routes_data!(route_data \\ nil) do
    now = NaiveDateTime.utc_now()
    min = @backoff[:min]
    update_throttle = @backoff[:update_throttle]

    if NaiveDateTime.diff(now, route_data.updated_at, :millisecond) < update_throttle do
      %{route_data | requested_at: now}
    else
      body = fetch_body(%Route.Ref{
        path: "routes.json",
        ref: routes_data_ref(),
        source: :s3,
        type: :json
      })

      cond do
        is_nil(route_data) or route_data.body != body ->
          if route_data.body != body do
            Process.cancel_timer(route_data.timer)
          end
          %Route.Data{
            body: body,
            updated_at: now,
            requested_at: now,
            next_update_seconds: min,
            timer: Route.schedule_routes_data_check(min)
          }

        route_data.body == body ->
          # TODO: decide how to handle this, I'm unsure what to update and schedule.
          # %{route_data | requested_at: now, timer: Route.schedule_routes_data_check(min)}

          route_data
      end
    end
  end

  @doc """
  Updates the given route ref in our list of routes and re-schedules our route ref timer.
  """
  @spec new_routes(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
  def new_routes(_new_route_ref, routes) do
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
    # get_json(routes_data)
    {routes_data, routes}
  end

  @spec check_new_routes!(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
  def check_new_routes!(_route_ref, routes) do
    routes
    # route_ref
    # |> check!()
    # |> new_routes()
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
