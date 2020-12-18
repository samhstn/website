defmodule Samhstn.RouteTest do
  use ExUnit.Case, async: true

  alias Samhstn.Route

  setup do
    {:ok, pid} = Route.start_link([])

    routes_body =
      Jason.encode!([
        %{
          path: "vimrc",
          type: :text,
          source: :url,
          ref: "https://raw.githubusercontent.com/samhstn/my-config/master/.vimrc"
        }
      ])

    routes = routes_body |> Jason.decode!() |> Enum.map(&Route.Ref.from_map/1)
    backoff = Application.get_env(:samhstn, :route_backoff)

    now = NaiveDateTime.utc_now()
    yesterday = now |> NaiveDateTime.add(-:timer.hours(24))
    recently = now |> NaiveDateTime.add(div(backoff[:min], 2))

    [
      pid: pid,
      routes_body: routes_body,
      routes: routes,
      yesterday: yesterday,
      recently: recently,
      now: now
    ]
    |> Keyword.merge(backoff)
  end

  test "get/1 returns path data" do
    assert {:ok, %Route.Ref{data: %Route.Data{body: body}, path: "vimrc", type: :text}} =
             Route.get("vimrc")

    assert body =~ "syntax enable"
  end

  test "stores initial routes data and routes after calling get/1", %{
    pid: pid,
    routes_body: routes_body,
    routes: routes
  } do
    assert {%Route.Data{body: ^routes_body}, ^routes} = :sys.get_state(pid)

    assert {:ok, _route_ref} = Route.get("vimrc")

    assert {%Route.Data{body: ^routes_body}, [%Route.Ref{data: %Route.Data{body: route_body}}]} =
             :sys.get_state(pid)

    assert route_body =~ "syntax enable"
  end

  test "get/1 with no update to route data and no recent request", %{
    pid: pid,
    routes_body: routes_body,
    yesterday: yesterday,
    now: now,
    max: max
  } do
    timer = Route.schedule_routes_data_check(max)

    :sys.replace_state(pid, fn {routes_data, routes} ->
      Process.cancel_timer(routes_data.timer)

      {
        %Route.Data{
          body: routes_body,
          fetched_at: yesterday,
          updated_at: yesterday,
          requested_at: yesterday,
          next_update_seconds: max,
          timer: timer
        },
        routes
      }
    end)

    {:ok, _route_ref} = Route.get("vimrc")

    assert {
             %Route.Data{
               body: ^routes_body,
               updated_at: ^yesterday,
               fetched_at: fetched_at,
               requested_at: requested_at,
               next_update_seconds: ^max,
               timer: ^timer
             },
             [%Route.Ref{}]
           } = :sys.get_state(pid)

    assert NaiveDateTime.diff(now, requested_at) == 0
    assert NaiveDateTime.diff(now, fetched_at) == 0
  end

  test "get/1 with recent request", %{pid: pid, recently: recently, now: now, max: max} do
    timer = Route.schedule_routes_data_check(max)

    :sys.replace_state(pid, fn {routes_data, routes} ->
      Process.cancel_timer(routes_data.timer)

      {
        %Route.Data{
          body: "[]",
          updated_at: recently,
          fetched_at: recently,
          requested_at: recently,
          next_update_seconds: max,
          timer: timer
        },
        routes
      }
    end)

    {:ok, _route_ref} = Route.get("vimrc")

    assert {
             %Route.Data{
               body: "[]",
               updated_at: ^recently,
               fetched_at: ^recently,
               requested_at: requested_at,
               next_update_seconds: ^max,
               timer: ^timer
             },
             [%Route.Ref{}]
           } = :sys.get_state(pid)

    assert NaiveDateTime.diff(now, requested_at) == 0
  end

  test "get/1 with updates to route data body", %{
    pid: pid,
    yesterday: yesterday,
    now: now,
    max: max,
    min: min,
    routes_body: routes_body
  } do
    timer = Route.schedule_routes_data_check(max)

    :sys.replace_state(pid, fn {routes_data, routes} ->
      Process.cancel_timer(routes_data.timer)

      {
        %Route.Data{
          body: "[]",
          updated_at: yesterday,
          fetched_at: yesterday,
          requested_at: yesterday,
          next_update_seconds: max,
          timer: timer
        },
        routes
      }
    end)

    {:ok, _route_ref} = Route.get("vimrc")

    assert {
             %Route.Data{
               body: ^routes_body,
               updated_at: updated_at,
               fetched_at: fetched_at,
               requested_at: requested_at,
               next_update_seconds: ^min,
               timer: new_timer
             },
             [%Route.Ref{}]
           } = :sys.get_state(pid)

    refute timer == new_timer
    assert NaiveDateTime.diff(now, fetched_at) == 0
    assert NaiveDateTime.diff(now, requested_at) == 0
    assert NaiveDateTime.diff(now, updated_at) == 0
  end
end
