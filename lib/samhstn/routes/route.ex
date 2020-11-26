defmodule Samhstn.Routes.Route do
  @enforce_keys [:path, :type, :body]
  defstruct [:path, :type, :body]

  @type t :: %__MODULE__{
          path: String.t(),
          type: :text | :html | :json,
          body: String.t()
        }

  @type error :: String.t()

  @spec parse_s3_ref(String.t()) :: map
  def parse_s3_ref("arn:aws:s3:::" <> rest) do
    [bucket | path] = String.split(rest, "/")

    %{bucket: bucket, object: Enum.join(path, "/")}
  end
end
