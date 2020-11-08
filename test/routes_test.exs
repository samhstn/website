defmodule SamhstnWeb.RoutesTest do
  use ExUnit.Case, async: false

  alias SamhstnWeb.Routes.Route

  test "SamhstnWeb.Routes.get/1" do
    assert {:ok, %Route{body: body, path: "vimrc", type: "text"}}
      = SamhstnWeb.Routes.get("vimrc")
    assert body =~ "syntax enable"
  end
end
