defmodule Samhstn.Routes.RouteRef do
  defstruct [:path, :type, :source, :ref]

  alias Samhstn.Routes.RouteRef

  def from_map(%{"path" => path, "type" => type, "source" => source, "ref" => ref}) do
    %RouteRef{path: path, type: type, source: source, ref: ref}
  end
end
