defmodule Samhstn.Routes do
  use GenServer

  @moduledoc """
  This module keeps track of the routes defined in a routes.json file.
  We will fetch the route if it doesn't exist in our cache, or serve from our cache.
  We run a background process to check if we need to update our routes data.
  """

  alias Samhstn.Routes.{Route, RouteRef}

  @routes Application.get_env(:samhstn, :routes)

  @spec get(String.t()) :: {:ok, Route.t()} | {:error, String.t() | :not_found}
  def get(route) do
    GenServer.call(__MODULE__, {:route, route})
  end

  @spec start_link(map()) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @type state :: {[RouteRef.t()], [Route.t()]}

  @impl true
  @spec init(any()) :: {:ok, state()}
  def init(_opts) do
    {:ok, {@routes.init(), []}}
  end

  @impl true
  @callback handle_call({:route, String.t()}, pid(), {}) ::
              {:reply, {:ok, Route.t()} | {:error, :not_found | String.t()}, state()}
  def handle_call({:route, path}, _from, {route_refs, cache}) do
    with nil <- Enum.find(cache, fn %Route{path: p} -> p == path end),
         nil <- Enum.find(route_refs, fn %RouteRef{path: p} -> p == path end) do
      {:reply, {:error, :not_found}, {route_refs, cache}}
    else
      %Route{} = route ->
        {:reply, {:ok, route}, {route_refs, cache}}

      %RouteRef{} = route_ref ->
        case @routes.get(route_ref) do
          {:ok, route} ->
            {:reply, {:ok, route}, {route_refs, [route | cache]}}

          {:error, error} ->
            {:reply, {:error, error}, {route_refs, cache}}
        end
    end
  end
end
