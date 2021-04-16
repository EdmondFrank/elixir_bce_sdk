defmodule ElixirBceSdk.Bos.Client do

  alias HTTPoison.Request
  alias ElixirBceSdk.Auth.BceSigner
  alias ElixirBceSdk.Auth.BceCredentials

  import ElixirBceSdk.Bos.Constants
  import ElixirBceSdk.Http.Constants

  @doc """
  List buckets of user.
  returns all buckets owned by the user.
  """
  def list_buckets() do
   http_get() |> send_request() |> wrap
  end

  @doc """
  Create bucket with specific name.
  """
  def create_bucket(bucket_name) do
    http_put() |> send_request(bucket_name) |> wrap
  end

  @doc """
  Delete bucket with specific name.
  """
  def delete_bucket(bucket_name) do
    http_delete() |> send_request(bucket_name) |> wrap
  end

  @doc """
  Check whether there is a bucket with specific name.
  """
  def bucket_exist?(bucket_name) do
    if http_head() |> send_request(bucket_name) |> status == 404, do: false, else: true
  end

  @doc """
  Get the region which the bucket located in.
  returns region of the bucket(bj/gz/sz).
  """
  def get_bucket_location(bucket_name) do
    params = %{ location: "" }
    http_get() |> send_request(bucket_name, params) |> wrap
  end

  @doc """
  Get Access Control Level of bucket.
  """
  def get_bucket_acl(bucket_name) do
    params = %{ acl: "" }
    http_get() |> send_request(bucket_name, params) |> wrap
  end

  @doc """
  Set Access Control Level of bucket by headers.
  """
  def set_bucket_canned_acl(bucket_name, canned_acl) do
    params = %{ acl: "" }
    headers = %{ http_bce_acl() => canned_acl }
    http_put() |> send_request(bucket_name, params, "", headers) |> wrap
  end

  @doc """
  Get Bucket Lifecycle
  """
  def get_bucket_lifecycle(bucket_name) do
    params = %{ lifecycle: "" }
    http_get() |> send_request(bucket_name, params) |> wrap
  end

  @doc """
  Put Bucket Lifecycle
  """
  def put_bucket_lifecycle(bucket_name, rules) do
    params = %{ lifecycle: "" }
    headers = %{ http_content_type() => http_json_type() }
    body = %{ rule: rules }
    http_put() |> send_request(bucket_name, params, "", headers, body) |> wrap
  end

  @doc """
  Put object to BOS.
  """
  def put_object(bucket_name, key, data, content_md5, content_length, options) do
    if content_length > bos_max_put_object_length() do
      {:error, "Object length should be less than #{bos_max_put_object_length()}"}
    else
      headers = Map.merge(%{
            http_content_md5() => content_md5,
            http_content_length() => content_length
                          }, options)

      headers = if headers[http_content_type()] == nil do
        Map.merge(headers, %{ http_content_type() => http_octet_stream() })
      else
        headers
      end
      http_put() |> send_request(bucket_name, %{}, key, headers, data) |> wrap
    end
  end

  defp base_url, do: "http://#{ElixirBceSdk.config[:endpoint]}"

  defp host, do: ElixirBceSdk.config[:endpoint]

  defp status(response) do
    case response do
      { :ok, res } -> res.status_code
      { :error, res } -> { :error, res }
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

    body = cond do
      is_map(body) -> (if map_size(body) == 0, do: "", else: Poison.encode!(body))
      true -> body
    end

    headers = Map.to_list(headers) ++ [
      { http_user_agent(), ElixirBceSdk.config[:user_agent] },
      { http_content_length(), byte_size(body) },
      { http_bce_date(), sign_date_time },
      { http_host(),  host() },
    ]

    authorization = BceSigner.sign(
      BceCredentials.credentials(),
      http_method,
      path,
      Enum.reduce(headers, %{}, fn {k,v}, acc -> Map.put(acc, k, v) end),
      params, timestamp
    )

    headers = headers ++ [{ http_authorization(), authorization }]

    %Request {
      method: http_method,
      url: base_url() <> path_uri,
      headers: headers,
      body: body,
    } |> HTTPoison.request
  end
end
