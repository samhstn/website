defmodule SamhstnWeb.RoutesTest do
  use ExUnit.Case, async: true

  alias Samhstn.Routes
  alias Samhstn.Routes.Route

  describe "Samhstn.Routes" do
    setup do
      {:ok, pid} = Routes.start_link([])

      {:ok, pid: pid}
    end

    test "get/1 returns data" do
      assert {:ok, %Route{body: body, path: "vimrc", type: :text}} = Routes.get("vimrc")
      assert body =~ "syntax enable"
    end
  end
end
