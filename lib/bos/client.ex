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
    http_get() |> send_request()
  end

  @doc """
  Create bucket with specific name.
  """
  def create_bucket(bucket_name) do
    http_put() |> send_request(bucket_name)
  end

  @doc """
  Delete bucket with specific name.
  """
  def delete_bucket(bucket_name) do
    http_delete() |> send_request(bucket_name)
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
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Get Access Control Level of bucket.
  """
  def get_bucket_acl(bucket_name) do
    params = %{ acl: "" }
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Set Access Control Level of bucket by body.
  """
  def set_bucket_acl(bucket_name, acl) do
    params = %{ acl: "" }
    headers = %{ http_content_type() => http_json_type() }
    body = %{ accessControlList: acl }
    http_put() |> send_request(bucket_name, params, "", headers, body)
  end

  @doc """
  Set Access Control Level of bucket by headers.
  """
  def set_bucket_canned_acl(bucket_name, canned_acl) do
    params = %{ acl: "" }
    headers = %{ http_bce_acl() => canned_acl }
    http_put() |> send_request(bucket_name, params, "", headers)
  end

  @doc """
  Get Bucket Lifecycle
  """
  def get_bucket_lifecycle(bucket_name) do
    params = %{ lifecycle: "" }
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Put Bucket Lifecycle
  """
  def put_bucket_lifecycle(bucket_name, rules) do
    params = %{ lifecycle: "" }
    headers = %{ http_content_type() => http_json_type() }
    body = %{ rule: rules }
    http_put() |> send_request(bucket_name, params, "", headers, body)
  end

  @doc """
  Delete Bucket Lifecycle
  """
  def delete_bucket_lifecycle(bucket_name) do
    params = %{ lifecycle: "" }
    http_delete() |> send_request(bucket_name, params)
  end

  @doc """
  Get Bucket Storageclass.
  """
  def get_bucket_storageclass(bucket_name) do
    params = %{ storageClass: "" }
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Put Bucket Storageclass
  """
  def put_bucket_storageclass(bucket_name, storage_class) do
    params = %{ storageClass: "" }
    headers = %{ http_content_length() => http_json_type() }
    body = %{ storageClass: storage_class }
    http_put() |> send_request(bucket_name, params, "", headers, body)
  end

  @doc """
  Put Bucket Cors
  """
  def put_bucket_cors(bucket_name, cors_configuration) do
    params = %{ cors: "" }
    headers = %{ http_content_type() => http_json_type() }
    body = %{ corsConfiguration: cors_configuration }
    http_put() |> send_request(bucket_name, params, "", headers, body)
  end

  @doc """
  Get Bucket Cors.
  """
  def get_bucket_cors(bucket_name) do
    params = %{ cors: "" }
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Delete Bucket Cors
  """
  def delete_bucket_cors(bucket_name) do
    params = %{ cors: "" }
    http_delete() |> send_request(bucket_name, params)
  end

  @doc """
  Get Bucket Logging.
  """
  def get_bucket_logging(bucket_name) do
    params = %{ logging: "" }
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Put Bucket Logging.
  """
  def put_bucket_logging(source_bucket, target_bucket, target_prefix \\ "") do
    params = %{ logging: "" }
    headers = %{ http_content_type() => http_json_type() }
    body = %{ targetBucket: target_bucket, targetPrefix: target_prefix }
    http_put() |> send_request(source_bucket, params, "", headers, body)
  end

  @doc """
  Delete Bucket Logging.
  """
  def delete_bucket_logging(bucket_name) do
    params = %{ logging: "" }
    http_delete() |> send_request(bucket_name, params)
  end

  @doc """
  Get Object Information of bucket.
  """
  def list_objects(bucket_name, options \\ %{}) do
    params = Map.merge(%{ maxKeys: 1000 }, options)
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Get object of bucket.
  """
  def get_object(bucket_name, key, range \\ nil, save_path \\ nil, return_body \\ true) do
    headers = cond do
      is_nil(range) -> %{}
      !is_list(range) ->
        raise BceClientException, message: "range type should be a array"
      !(length(range) == 2) ->
        raise BceClientException, message: "range should have length of 2"
      !Enum.all?([], &is_number/1) ->
        raise BceClientException, message: "range all element should be integer"
      true ->
        [s, e] = range
        %{ http_range() => "bytes=#{s}-#{e}" }
    end
    http_get() |> send_request(bucket_name, %{}, key, headers, "", save_path, return_body)
  end

  @doc """
  Get object as string
  """
  def get_object_as_string(bucket_name, key, range \\ nil) do
    get_object(bucket_name, key, range)
  end

  @doc """
  Get object to file
  """
  def get_object_to_file(bucket_name, key, save_path, range \\ nil) do
    get_object(bucket_name, key, range, save_path, true)
  end

  @doc """
  Get mete of object
  """
  def get_object_meta_data(bucket_name, key) do
    http_head() |> send_request(bucket_name, %{}, key)
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
      http_put() |> send_request(bucket_name, %{}, key, headers, data)
    end
  end

  defp base_url, do: "http://#{ElixirBceSdk.config[:endpoint]}"

  defp host, do: ElixirBceSdk.config[:endpoint]

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

    %Request{ method: http_method, url: base_url() <> path_uri, headers: headers, body: body, }
    |> HTTPoison.request
    |> generate_response(return_body)
    |> generate_file(save_path)
  end

  defp generate_response(response, return_body) do
    case response do
      { :ok, res } ->
        if return_body do
          res.body
        else
          case  Poison.decode(res.body) do
            { :ok, decode_body } -> { :ok, res.status_code, decode_body }
            { :error, %{value: ""} } -> { :ok, res.status_code, res.headers }
            { :error, _raw } -> { :ok, res.status_code, res.body }
          end
        end
      { :error, reason } -> { :error, reason }
    end
  end

  defp generate_file(response, save_path) do
    if save_path do
      case File.write(save_path, response) do
        :ok -> {:ok, "Response save file path: #{save_path}"}
        {:error, reason} -> { :error, reason }
      end
    else
      response
    end
  end

  defp status(response) do
    case response do
      { :ok, status, _res } -> status
      { :error, res } -> { :error, res }
    end
  end
end
