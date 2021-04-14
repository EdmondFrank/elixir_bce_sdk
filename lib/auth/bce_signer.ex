defmodule ElixirBceSdk.Auth.BceSigner do
  @moduledoc """
  module about authorization
  Reference https://cloud.baidu.com/doc/Reference/s/Njwvz1wot
  """
  alias ElixirBceSdk.Http.Constants
  alias ElixirBceSdk.Auth.BceCredentials
  def get_canonical_headers(headers, nil), do: get_canonical_headers(headers, ["host", "content-md5", "content-length", "content-type"])

  def get_canonical_headers(headers, headers_to_sign) do

    canonical_headers = headers
    |> Enum.filter(fn {k,v} ->
      to_string(v) |> String.trim != "" && (String.downcase(k) in headers_to_sign || String.downcase(k) |> String.starts_with?(Constants.bce_prefix))
    end)

    ret_array = canonical_headers
    |> Enum.map(fn {k,v} ->
      "#{String.downcase(k) |> URI.encode_www_form}:#{to_string(v) |> String.trim |> URI.encode_www_form}"
    end)
    |> Enum.join("\n")

    headers_array = canonical_headers
    |> Enum.map(fn {k,_} -> String.downcase(k) end)

    { ret_array, headers_array }
  end

  def get_canonical_uri_path(path) do
    if to_string(path) == "" do
      "/"
    else
      encoded_path = to_string(path) |> URI.encode_www_form |> String.replace("%2F", "/")
      if encoded_path |> String.starts_with?("/") do
        encoded_path
      else
        "/#{encoded_path}"
      end
    end
  end

  def get_canonical_querystring(nil, _), do: ""
  def get_canonical_querystring(params, _) when map_size(params) == 0, do: ""
  def get_canonical_querystring(params = %{}, for_signature) do
    Enum.filter(params, fn {k, _} ->
      !for_signature || String.downcase(to_string(k)) != String.downcase(Constants.authorization)
    end)
    |> Enum.map(fn {k, v} ->
      "#{URI.encode_www_form(to_string(k))}=#{URI.encode_www_form(to_string(v))}"
    end)
    |> Enum.join("&")
  end

  def sign(
    credentials = %BceCredentials{},
    http_method,
    path,
    headers,
    params,
    timestamp \\ nil,
    expiration_in_seconds \\ 1800,
    headers_to_sign \\ nil) do

    timestamp = (if timestamp == nil, do: :os.system_time(:second), else: timestamp)

    sign_date_time = DateTime.from_unix!(timestamp)
    |> DateTime.to_iso8601

    sign_key_info = "bce-auth-v1/#{credentials.access_key_id}/#{sign_date_time}/#{expiration_in_seconds}"

    sign_key = :crypto.hmac(:sha256, credentials.secret_access_key, sign_key_info)
    |> Base.encode16
    |> String.downcase

    canonical_uri = get_canonical_uri_path(path)

    canonical_querystring = get_canonical_querystring(params, true)

    {canonical_headers, headers_to_sign} = get_canonical_headers(headers, headers_to_sign)

    canonical_request = Enum.join([http_method, canonical_uri, canonical_querystring, canonical_headers], "\n")

    signature = :crypto.hmac(:sha256, sign_key, canonical_request)
    |> Base.encode16
    |> String.downcase

    headers_str = Enum.join(headers_to_sign, ";")

    "#{sign_key_info}/#{headers_str}/#{signature}"
  end
end
