defmodule SamhstnWeb.Routes.RouteRef do
  defstruct [:path, :type, :source, :ref]

  alias SamhstnWeb.Routes.RouteRef

  def from_map(%{"path" => path, "type" => type, "source" => source, "ref" => ref}) do
    %RouteRef{path: path, type: type, source: source, ref: ref}
  end
end

defmodule SamhstnWeb.Routes.Route do
  defstruct [:path, :type, :body]

  alias SamhstnWeb.Routes.{Route, RouteRef}

  def get(%RouteRef{source: "url"} = route_ref) do
    case HTTPoison.get(route_ref.ref) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end

  def get(%RouteRef{source: "s3"} = route_ref) do
    {bucket, path} = from_arn(route_ref.ref)

    body =
      ExAws.S3.download_file(bucket, path, :memory)
      |> ExAws.stream!()
      |> Enum.join()

    {:ok, %Route{path: route_ref.path, type: route_ref.type, body: body}}
  end

  defp from_arn("arn:aws:s3:::" <> rest) do
    rest |> String.split("/") |> List.to_tuple()
  end
end

defmodule SamhstnWeb.Routes.Client do
  @moduledoc """
  Provides routing for urls and content in s3 buckets,
  routes according to content of `routes.json` in our "assets" bucket.
  """
  alias SamhstnWeb.Routes.{Route, RouteRef}

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

defmodule SamhstnWeb.Routes.Sandbox do
  @moduledoc """
  Provides simple routing for simple urls according to content of priv/routes.json
  """
  alias SamhstnWeb.Routes.{Route, RouteRef, InMemory}

  require Logger

  def init() do
    with path <- Path.join(File.cwd!(), "priv/assets/routes.json"),
         {:ok, json} <- File.read(path),
         {:ok, parsed} <- Jason.decode(json)
    do
      Enum.map(parsed, &RouteRef.from_map/1)
    else
      {:error, error} ->
        Logger.error(error)
        Logger.error("Problem reading routes.json")

        InMemory.init()
    end
  end

  def get(%RouteRef{source: "url"} = route_ref), do: Route.get(route_ref)

  def get(%RouteRef{source: "s3"} = route_ref) do
    SamhstnWeb.Routes.Route.get(route_ref)
  end
  # defdelegate get(route), to: SamhstnWeb.Routes.InMemory
end

defmodule SamhstnWeb.Routes.InMemory do
  alias SamhstnWeb.Routes.{Route, RouteRef}

  def init() do
    [
      %RouteRef{
        path: "vimrc",
        type: "text",
        source: "url",
        ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc"
      }
    ]
  end

  def get(%RouteRef{path: "vimrc"} = route_ref) do
    body = """
    syntax enable

    set number ignorecase smartcase incsearch autoindent
    """

    {:ok, %Route{path: "vimrc", type: route_ref.type, body: body}}
  end
end

defmodule SamhstnWeb.Routes do
  use GenServer

  alias SamhstnWeb.Routes.{Route, RouteRef}

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
