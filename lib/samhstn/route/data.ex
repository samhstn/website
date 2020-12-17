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

  @doc """
  Fetches the body for a given route ref.

  This function needs to be defined where this module macro is used.
  """
  @callback fetch_body(Route.Ref.t()) :: {:ok, String.t()} | {:error, String.t()}

  defmacro __using__(_) do
    quote do
      alias Samhstn.Route

      # This @behaviour throws a warning if the @callback functions aren't defined
      # where this is used.
      @behaviour Route.Data

      @assets_bucket Application.fetch_env!(:samhstn, :assets_bucket)
      @backoff Application.fetch_env!(:samhstn, :route_backoff)

      @spec get_routes_data!() :: Route.Data.t()
      def get_routes_data!(), do: get_routes_data!(nil)

      @doc """
      Fetches the routes data and schedules route updates.
      """
      @spec get_routes_data!(Route.Data.t() | nil) :: Route.Data.t()
      def get_routes_data!(route_data) do
        now = NaiveDateTime.utc_now()
        min = @backoff[:min]
        update_throttle = @backoff[:update_throttle]

        if not is_nil(route_data) &&
             NaiveDateTime.diff(now, route_data.updated_at, :millisecond) < update_throttle do
          %{route_data | requested_at: now}
        else
          case fetch_body(%Route.Ref{
                 path: "routes.json",
                 ref: {Application.fetch_env!(:samhstn, :assets_bucket), "routes.json"},
                 source: :s3,
                 type: :json
               }) do
            {:ok, body} ->
              cond do
                is_nil(route_data) or route_data.body != body ->
                  if not is_nil(route_data) && route_data.body != body do
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

            {:error, error} ->
              throw(error)
          end
        end
      end

      @doc """
      Populates the :data field in our route ref.
      This contains metadata as well as scheduling an update for this route.
      """
      @spec get(Route.Ref.t()) :: {:ok, Route.Ref.t()} | {:error, String.t()}
      def get(%Route.Ref{path: path} = route_ref) do
        now = NaiveDateTime.utc_now()
        min = @backoff[:min]

        case fetch_body(route_ref) do
          {:ok, body} ->
            cond do
              is_nil(route_ref.data) ->
                timer = Route.schedule_check(path, min)

                data = %Route.Data{
                  body: body,
                  updated_at: now,
                  requested_at: now,
                  next_update_seconds: min,
                  timer: timer
                }

                {:ok, %{route_ref | data: data}}

              route_ref.data.body == body ->
                {:ok, route_ref}

              route_ref.data.body != body ->
                {:ok, route_ref}
            end

          {:error, error} ->
            {:error, error}
        end
      end

      @spec get!(Route.Ref.t()) :: Route.Ref.t()
      def get!(route_ref = %Route.Ref{}) do
        case get(route_ref) do
          {:ok, route_ref} ->
            route_ref

          {:error, error} ->
            throw(error)
        end
      end

      @doc """
      Updates the given route ref in our list of routes and re-schedules our route ref timer.
      """
      @spec new_routes(Route.Ref.t(), [Route.Ref.t()]) :: [Route.Ref.t()]
      def new_routes(new_route_ref, routes) do
        Enum.map(routes, fn route ->
          if route.path == new_route_ref.path do
            new_route_ref
          else
            route
          end
        end)
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

      @spec check_new_routes_data_and_routes!(Route.Data.t(), [Route.Ref.t()]) :: Route.state()
      def check_new_routes_data_and_routes!(routes_data, routes) do
        {routes_data, routes}
      end
    end
  end
end
