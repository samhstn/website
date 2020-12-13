defmodule Samhstn.Route do
  @moduledoc """
  This module keeps track of the routes defined in a routes.json file.
  We will fetch the route if it doesn't exist in our cache, or serve from our cache if it does.
  We run background processes to check if we need to update our routes data.
  If the route has been recently updated or visited, we will poll more regularly for changes.
  We implement a cache update backoff for routes which aren't active and for updates to all of our routes.
  """

  use GenServer
  import Logger
  alias Samhstn.Route

  @route Application.get_env(:samhstn, :route)
  @route_backoff Application.get_env(:samhstn, :routes_backoff)

  @type state :: {Route.Data.t(), [Route.Ref.t()]}

  @spec get(String.t()) :: {:ok, Route.Ref.t()} | {:error, String.t() | :not_found}
  def get(path) do
    GenServer.cast(__MODULE__, :get_routes_data)
    GenServer.call(__MODULE__, {:get, path})
  end

  @spec start_link(map) :: {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl GenServer
  @spec init(any()) :: {:ok, state}
  def init(_opts), do: {:ok, @route.init()}

  @impl GenServer
  @callback handle_call({:get, String.t()}, pid, state) ::
              {:reply, {:ok, Route.t()} | {:error, :not_found | String.t()}, state}
  def handle_call({:get, path}, _from, {routes_data, routes} = state) do
    with nil <- Enum.find(routes, fn %Route.Ref{path: p} -> p == path end) do
      {:reply, {:error, :not_found}, state}
    else
      %Route.Ref{data: %Route.Data{}} = route_ref ->
        GenServer.cast(__MODULE__, {:get, route_ref})

        {:reply, {:ok, route_ref}, state}

      %Route.Ref{} = route_ref ->
        case @route.get(route_ref) do
          {:ok, new_route_ref} ->
            {:reply, {:ok, route_ref}, {routes_data, @route.new_routes(routes, new_route_ref)}}

          {:error, error} ->
            {:reply, {:error, error}, state}
        end
    end
  end

  @impl GenServer
  @callback handle_cast({:get, Route.Ref.t()}, state) :: {:noreply, state}
  def handle_cast({:get, route_ref}, {routes_data, routes}) do
    {:noreply, {routes_data, @route.get_new_routes!(routes, route_ref)}}
  end

  def handle_cast(:get_routes_data, {routes_data, routes} = state) do
    {:noreply, @route.get_new_routes_data_and_routes!(routes_data, routes)}
  end

  @impl GenServer
  @callback handle_info({:check, Route.Ref.t()}, state) :: {:noreply, state}
  def handle_info({:check, route_ref}, {routes_data, routes}) do
    # TODO: make route_ref.path uniform length with whitespace padding
    Logger.info("#{route_ref.path}:Checking for updates...")

    {:noreply, {routes_data, @route.check_new_routes!(routes, route_ref)}}
  end

  def handle_info(:check_routes_data, {routes_data, routes}) do
    Logger.info("#{route_ref.path}:Checking for route json updates...")

    {:noreply, @route.check_new_routes_data_and_routes!(routes_data, routes)}
  end
end
