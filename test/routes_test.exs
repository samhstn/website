defmodule Samhstn.RoutesTest do
  use ExUnit.Case, async: true

  alias Samhstn.Routes
  alias Samhstn.Routes.{Route, RouteRef}

  describe "Samhstn.Routes" do
    setup do
      {:ok, pid} = Routes.start_link([])

      {:ok, pid: pid}
    end

    test "get/1 returns data" do
      assert {:ok, %Route{body: body, path: "vimrc", type: :text}} = Routes.get("vimrc")
      assert body =~ "syntax enable"
    end

    test "stores initial routes data as RouteRefs in state and adds Route data after calling get/1",
         %{pid: pid} do
      route_ref = %RouteRef{
        path: "vimrc",
        ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc",
        source: "url",
        type: :text
      }

      assert {[^route_ref], []} = :sys.get_state(pid)
      assert {:ok, _} = Routes.get("vimrc")

      assert {[^route_ref], [%Route{body: body, path: "vimrc", type: :text}]} =
               :sys.get_state(pid)

      assert body =~ "syntax enable"
    end
  end
end
