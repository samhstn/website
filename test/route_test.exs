defmodule Samhstn.RouteTest do
  use ExUnit.Case, async: true

  alias Samhstn.Route

  def routes_body_json() do
    Jason.encode!([
      %{
        path: "vimrc",
        type: :text,
        source: :url,
        ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc"
      }
    ])
  end

  setup do
    {:ok, pid} = Route.start_link([])

    {:ok, pid: pid}
  end

  test "get/1 returns data" do
    assert {:ok, %Route.Ref{data: %Route.Data{body: body}, path: "vimrc", type: :text}} =
             Route.get("vimrc")

    assert body =~ "syntax enable"
  end

  test "stores initial routes data in state and adds Route.Data after calling get/1", %{pid: pid} do
    routes_body = routes_body_json()
    [route_ref] = routes_body_json() |> Jason.decode!() |> Enum.map(&Route.Ref.from_map/1)

    assert {%Route.Data{body: ^routes_body}, [^route_ref]} = :sys.get_state(pid)

    assert {:ok, _} = Route.get("vimrc")

    assert {%Route.Data{body: ^routes_body}, [%Route.Ref{data: %Route.Data{body: route_body}}]} =
             :sys.get_state(pid)

    assert route_body =~ "syntax enable"
  end
end
