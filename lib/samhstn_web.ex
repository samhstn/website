defmodule SamhstnWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: SamhstnWeb

      import Plug.Conn
      alias SamhstnWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/samhstn_web/templates",
        namespace: SamhstnWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import SamhstnWeb.ErrorHelpers
      alias SamhstnWeb.Router.Helpers, as: Routes
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
