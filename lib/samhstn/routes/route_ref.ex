defmodule Samhstn.Routes.RouteRef do
  @enforce_keys [:path, :type, :source, :ref]
  defstruct [:path, :type, :source, :ref]

  @type t() :: %__MODULE__{
          path: String.t(),
          type: :html | :json | :text,
          source: String.t(),
          ref: String.t()
        }

  alias Samhstn.Routes.RouteRef

  defp type_to_atom("html"), do: :html
  defp type_to_atom("json"), do: :json
  defp type_to_atom("text"), do: :text

  @spec from_map(map) :: RouteRef.t()
  def from_map(%{"path" => path, "type" => type, "source" => source, "ref" => ref}) do
    %RouteRef{path: path, type: type_to_atom(type), source: source, ref: ref}
  end
end
