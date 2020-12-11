defmodule Samhstn.Routes.CacheTest do
  use ExUnit.Case, async: true

  alias Samhstn.Routes.{Cache, Route}

  describe "Samhstn.Routes.Cache.update" do
    test "empty cache returns an empty cache" do
      assert Cache.update([]) == []
    end

    test "updates when user_requested_at is before last_updated_at" do
      now = NaiveDateTime.utc_now()

      assert [{user_requested_at, last_updated_at, %Route{body: body}}] =
        Cache.update([{NaiveDateTime.add(now, -10), now, %Route{body: "body", path: "vimrc", type: :text}}])
      assert NaiveDateTime.compare(now, user_requested_at) == :gt
      assert body =~ "syntax on"
    end
  end

  describe "Samhstn.Routes.Cache.update_frequency" do
    test "empty list returns :none" do
      assert Cache.update_frequency([]) == :none
    end
  end
end
