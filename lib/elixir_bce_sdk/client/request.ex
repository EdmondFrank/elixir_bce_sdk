defmodule ElixirBceSdk.Client.Request do
  @moduledoc """
  Internal module
  """
  import ElixirBceSdk.Config, only: [user_agent: 0]
  alias ElixirBceSdk.Auth.BceSigner
  alias ElixirBceSdk.Auth.BceCredentials

  @default_content_type "application/octet-stream"

  defstruct http_method: "GET",
    host: nil,
    path: nil,
    scheme: "https",
    resource: nil,
    params: %{},
    key: "",
    headers: %{},
    body: %{},
    timestamp: nil,
    save_path: nil,
    return_body: false

  def build(fields) do
    __MODULE__
    |> struct!(fields)
    |> ensure_essential_headers()
  end

  defp ensure_essential_headers(%__MODULE__{} = req) do

    req = Map.put(req, :timestamp, :os.system_time(:second))

    headers =
      req.headers
      |> Map.put_new("Host", req.host)
      |> Map.put_new("User-Agent", user_agent())
      |> Map.put_new_lazy("Content-Type", fn -> parse_content_type(req) end)
      |> Map.put_new_lazy("Content-MD5", fn -> calc_content_md5(req) end)
      |> Map.put_new_lazy("Content-Length", fn -> byte_size(req.body) end)
      |> Map.put_new_lazy("x-bce-date", fn -> sign_date_time(req.timestamp) end)

    Map.put(req, :headers, headers)
  end

  def build_signed(fields) do
    build(fields)
    |> set_authorization_header()
  end

  def query_url(%__MODULE__{} = req) do
    URI.to_string(
      %URI{
        scheme: req.scheme,
        host: req.host,
        path: req.path,
        query: BceSigner.get_canonical_querystring(req.params, false)
      }
    )
  end

  defp parse_content_type(%{resource: resource}) do
    case Path.extname(resource) do
      "." <> name -> MIME.type(name)
      _ -> @default_content_type
    end
  end

  defp calc_content_md5(%{body: ""}), do: ""
  defp calc_content_md5(%{body: body}) do
    :crypto.hash(:md5, body) |> Base.encode64()
  end

  defp sign_date_time(timestamp) do
    timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_iso8601()
  end

  defp set_authorization_header(%__MODULE__{} = req) do
    authorization = BceSigner.sign(
      BceCredentials.credentials(),
      req.http_method,
      req.path,
      Enum.reduce(req.headers, %{}, fn {k,v}, acc -> Map.put(acc, k, v) end),
      req.params,
      req.timestamp
    )
    put_in(req.headers["Authorization"], authorization)
  end
end
