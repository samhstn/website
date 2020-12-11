defmodule Samhstn.Routes do
  @moduledoc """
  This module keeps track of the routes defined in a routes.json file.
  We will fetch the route if it doesn't exist in our cache, or serve from our cache if it does.
  We run background processes to check if we need to update our routes data.
  If the route has been recently updated or visited, we will poll more regularly for changes.
  We implement a cache update backoff for routes which aren't active and for updates to all of our routes.
  """

  use GenServer

  alias Samhstn.Routes.RouteRef
  alias Samhstn.Routes.RouteRef.{Cache, RouteFile}

  import Logger

  @routes Application.get_env(:samhstn, :routes)
  @routes_backoff Application.get_env(:samhstn, :routes_backoff)

  @type state :: {RouteRef.Cache.t(), [RouteRef.t()]}

  @spec get(String.t()) :: {:ok, Route.t()} | {:error, String.t() | :not_found}
  def get(route) do
    GenServer.call(__MODULE__, {:route, route})
  end

  @spec start_link(map) :: {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  @spec init(any()) :: {:ok, state}
  def init(_opts) do
    now = NaiveDateTime.utc_now()
    initial_routes = @routes.init()
    timer = schedule_update(now, now, initial_routes)

    {:ok, {now, now, initial_routes, timer}}
  end

  @impl GenServer
  @callback handle_call({:route, String.t()}, pid, state) ::
              {:reply, {:ok, Route.t()} | {:error, :not_found | String.t()}, state}
  def handle_call({:route, path}, _from, {user_requested_at, last_updated_at, routes, timers}) do
    with nil <- Enum.find(state, fn %RouteRef{path: p} -> p == path end)
      {:reply, {:error, :not_found}, state}
    else
      %RouteRef{cache: %Cache{}} = route_ref ->
        schedule_updates(:short)
        {:reply, {:ok, RouteRef.route(route_ref)}, user_request(state, route)}

      %RouteRef{} = route_ref ->
        case @routes.get(route_ref) do
          {:ok, route_ref} ->
            now = NaiveDateTime.utc_now()
            {:reply, {:ok, RouteRef.route(route_ref)}, [{now, now, route_ref} | cache]}

          {:error, error} ->
            {:reply, {:error, error}, {route_refs, cache}}
        end
    end
  end

  @impl GenServer
  @callback handle_info(:update_cache, state) :: {:noreply, state}
  def handle_info(:update_cache, {update_frequency, route_refs, cache}) do
    Logger.info("Checking for updates...")

    new_cache = Cache.update(cache)
    new_update_frequency = Cache.update_frequency(new_cache)

    schedule_updates(new_update_frequency)

    {:noreply, {new_update_frequency, route_refs, new_cache}}
  end

  defp update_timers(ms, timer) do
    &Process.cancel_timer(timer)

    schedule_update(ms)
  end

  defp schedule_updates() do

  end

  defp schedule_updates(:short), do: Process.send_after(self(), :update_cache, @ten_seconds)
  defp schedule_updates(:medium), do: Process.send_after(self(), :update_cache, @twenty_minutes)
  defp schedule_updates(:long), do: Process.send_after(self(), :update_cache, @two_hours)

end
