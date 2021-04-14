defmodule ElixirBceSdk.Bos.Client do

  alias HTTPoison.Request
  alias ElixirBceSdk.Http.Constants
  alias ElixirBceSdk.Auth.BceSigner
  alias ElixirBceSdk.Auth.BceCredentials


  @doc """
  List buckets of user.
  returns all buckets owned by the user.
  """
  def list_buckets() do
   send_request("GET") |> wrap
  end

  @doc """
  Create bucket with specific name.
  """
  def create_bucket(bucket_name) do
    send_request("PUT", bucket_name) |> wrap
  end

  @doc """
  Delete bucket with specific name.
  """
  def delete_bucket(bucket_name) do
    send_request("DELETE", bucket_name) |> wrap
  end

  @doc """
  Check whether there is a bucket with specific name.
  """
  def bucket_exist?(bucket_name) do
    if status(send_request("HEAD", bucket_name)) == 404, do: false, else: true
  end

  @doc """
  Get the region which the bucket located in.
  returns region of the bucket(bj/gz/sz).
  """
  def get_bucket_location(bucket_name) do
    send_request("GET", bucket_name, %{ location: "" }) |> wrap
  end

  @doc """
  Get Access Control Level of bucket.
  """
  def get_bucket_acl(bucket_name) do
    send_request("GET", bucket_name, %{ acl: "" }) |> wrap
  end

  @doc """
  Set Access Control Level of bucket by headers.
  """
  def set_bucket_canned_acl(bucket_name, canned_acl) do
    params = %{ acl: "" }
    headers = %{ "x-bce-acl" => canned_acl }
    send_request("PUT", bucket_name, params, "", headers) |> wrap
  end

  defp base_url, do: "http://#{ElixirBceSdk.config[:endpoint]}"

  defp host, do: ElixirBceSdk.config[:endpoint]

  defp credentials do
    %BceCredentials{
      access_key_id: ElixirBceSdk.config[:access_key_id],
      secret_access_key: ElixirBceSdk.config[:secret_access_key],
      security_token: ElixirBceSdk.config[:security_token]
    }
  end

  defp status(response) do
    case response do
      { :ok, res } -> res.status_code
      { :error, res } -> { :error, 500 }
    end
  end

  defp wrap(response) do
    case response do
      { :ok, res } -> case  Poison.decode(res.body) do
                        { :ok, decode_body } -> { :ok, decode_body }
                        { :error, _raw } -> { :ok, res.body }
                      end
      { :error, reason } -> { :error, reason }
    end
  end

  defp send_request(
    http_method,
    bucket_name \\ "",
    params \\ %{},
    key \\ "",
    headers \\ %{},
    body \\ %{},
    save_path \\ nil,
    return_body \\ false) do

    path = Path.join(["/", bucket_name, key])

    query = BceSigner.get_canonical_querystring(params, false)
    path_uri = if query != "", do: "#{path}?#{query}", else: path

    timestamp = :os.system_time(:second)

    sign_date_time = DateTime.from_unix!(timestamp)
    |> DateTime.to_iso8601

    body = (if map_size(body) == 0, do: "", else: Poison.encode!(body))

    headers = Map.to_list(headers) ++ [
      { "UserAgent", ElixirBceSdk.config[:user_agent] },
      { "Content-Length", byte_size(body) },
      { "x-bce-date", sign_date_time },
      { "Host",  host },
    ]

    authorization = BceSigner.sign(
      credentials, http_method, path,
      Enum.reduce(headers, %{}, fn {k,v}, acc -> Map.put(acc, k, v) end),
      params, timestamp
    )

    headers = headers ++ [{ Constants.authorization, authorization }]
    %Request {
      method: http_method,
      url: base_url <> path_uri,
      headers: headers,
      body: body,
    } |> HTTPoison.request
  end
end
