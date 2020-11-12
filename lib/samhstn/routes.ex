defmodule Samhstn.Routes do
  use GenServer

  alias Samhstn.Routes.{Route, RouteRef}

  @routes Application.get_env(:samhstn, :routes)

  def get(route) do
    GenServer.call(__MODULE__, {:route, route})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, {@routes.init(), []}}
  end

  @impl true
  def handle_call({:route, path}, _from, {route_refs, cache}) do
    with nil <- Enum.find(cache, fn %Route{path: p} -> p == path end),
         nil <- Enum.find(route_refs, fn %RouteRef{path: p} -> p == path end)
    do
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
