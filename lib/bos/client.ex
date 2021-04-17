defmodule ElixirBceSdk.Bos.Client do

  alias HTTPoison.Request
  alias ElixirBceSdk.Utils
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
      raise BceClientException, message: "Object length should be less than #{bos_max_put_object_length()}"
    else
      headers = Map.merge(
        %{
          http_content_md5() => content_md5,
          http_content_length() => content_length
        }, options
      )

      headers = if headers[http_content_type()] == nil do
        Map.merge(headers, %{ http_content_type() => http_octet_stream() })
      else
        headers
      end
      http_put() |> send_request(bucket_name, %{}, key, headers, data)
    end
  end

  @doc """
  Create object and put content of string to the object.
  """
  def put_object_from_string(bucket_name, key, data, options \\ %{}) do
    data_md5 = :crypto.hash(:md5, data) |> Base.encode64
    put_object(bucket_name, key, data, data_md5, String.length(data), options)
  end

  @doc """
  Put object and put content of file to the object.
  """
  def put_object_from_file(bucket_name, key, file_name, options \\ %{}) do
    options = if options[http_content_type()] == nil do
      Map.put(options, http_content_type(), MIME.from_path(file_name))
    else
      options
    end

    case File.read(file_name) do
      {:ok, data} ->
        content_length = byte_size(data)
        data_md5 = Utils.get_md5_from_file(file_name, content_length)
        put_object(bucket_name, key, data, data_md5, content_length, options)
      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc """
  Get an authorization url with expire time
  """
  def generate_pre_signed_url(bucket_name, key, options \\ %{}) do
    headers = options["headers"] || %{}
    params = options["params"] || %{}

    path = "/" <> key

    headers = Map.put(headers, http_host(), "#{bucket_name}.#{host()}")

    signture = BceSigner.sign(
      BceCredentials.credentials(),
      http_get(),
      path,
      headers,
      params,
      options["timestamp"],
      options["expiration_in_seconds"] || 1800,
      options['headers_to_sign']
    )

    params = Map.put(params, Utils.to_s_down(http_authorization()), signture)

    query = BceSigner.get_canonical_querystring(params, false)
    path_uri = if query != "", do: "#{path}?#{query}", else: path

    base_url(bucket_name) <> path_uri
  end


  @doc """
  Copy one object to another object.
  """
  def copy_object(source_bucket_name, source_key, target_bucket_name, target_key, options \\ %{}) do
    headers = options

    headers = if headers["etag"] != nil do
      Map.put(headers, http_bce_copy_source_if_match(), headers['etag'])
    else
      headers
    end

    headers = case headers["user-metadata"] do
                nil ->
                  Map.put(headers, http_bce_copy_meta_data_directive(), "copy")
                _ ->
                  headers = Map.put(headers, http_bce_copy_meta_data_directive(), "replace")
                  populate_headers_with_user_metadata(headers)
              end

    headers = Map.put(headers,
      http_bce_copy_source(),
      BceSigner.get_canonical_uri_path("/#{source_bucket_name}/#{source_key}")
    )
    http_put() |> send_request(target_bucket_name, %{}, target_key, headers)
  end

  @doc """
  Put an appendable object to BOS or add content to an appendable object.
  """
  def append_object(bucket_name, key, data, offset, content_md5, content_length, options \\ %{}) do
    if content_length > bos_max_append_object_length() do
      raise BceClientException, message: "Object length should be less than #{bos_max_append_object_length()}. Use multi-part upload instead."
    end
    params = %{ append: "" }
    params = if offset != nil do
      Map.put(params, :offset, offset)
    else
      params
    end
    headers = Map.merge(
      %{
        http_content_md5() => content_md5,
        http_content_length() => content_length,
      },options
    )
    headers = if headers["user-metadata"] != nil do
      populate_headers_with_user_metadata(headers)
    else
      headers
    end

    http_post() |> send_request(bucket_name, params, key, headers, data)
  end

  @doc """
  Create an appendable object and put content of string to the object
  or add content of string to an appendable object.
  """
  def append_object_from_string(bucket_name, key, data, options \\ %{}) do
    data_md5 = :crypto.hash(:md5, data) |> Base.encode64
    append_object(bucket_name, key, data, options["offset"], data_md5, String.length(data), options)
  end

  @doc """
  Delete Object
  """
  def delete_object(bucket_name, key) do
    http_delete() |> send_request(bucket_name, %{}, key)
  end

  @doc """
  Initialize multi_upload_file.
  """
  def initialize_multipart_upload(bucket_name, key, options \\ %{}) do
    params = %{ uploads: "" }
    http_post() |> send_request(bucket_name, params, key, options)
  end

  @doc """
  Upload a part
  """
  def upload_part(bucket_name, key, upload_id, part_number, part_size, data, options \\ %{}) do
    headers = options
    params = %{ partNumber: part_number, uploadId: upload_id }
    if part_number < bos_min_part_number() || part_number > bos_max_part_number() do
      raise BceClientException, message: "Invalid part_number#{part_number}, The valid range is from #{bos_min_part_number()} to #{bos_max_part_number()}"
    end

    if part_size > bos_max_put_object_length() do
      raise BceClientException, message: "Single part length should be less than #{bos_max_put_object_length()}"
    end

    headers = Map.merge(headers,
      %{
        http_content_length() => part_size,
        http_content_type() => http_octet_stream(),
      }
    )

    http_post() |> send_request(bucket_name, params, key, headers, data)
  end

  @doc """
  Upload a part from file.
  """
  def upload_part_from_file(bucket_name, key, upload_id, part_number,
    part_size, file_name, offset \\ 0, options \\ %{}) do
    case :file.open(file_name, [:binary]) do
      {:ok, f} ->
        {:ok, data} = :file.pread(f, offset, part_size)
        :file.close(f)
        upload_part(bucket_name, key, upload_id, part_number, part_size, data, options)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Copy upload part.
  """
  def upload_part_copy(source_bucket_name, source_key, target_bucket_name, target_key, upload_id,
    part_number, part_size, offset, options \\ %{}) do
    headers = options
    params = %{ partNumber: part_number, uploadId: upload_id }

    headers = if headers["user-metadata"] != nil do
      populate_headers_with_user_metadata(headers)
    else
      headers
    end

    headers = if headers["etag"] != nil do
      Map.put(headers, http_bce_copy_source_if_match(), headers['etag'])
    else
      headers
    end

    headers = Map.put(headers,
      http_bce_copy_source(),
      BceSigner.get_canonical_uri_path("/#{source_bucket_name}/#{source_key}")
    )

    headers = Map.put(headers,
      http_bce_copy_source_range(),
      "bytes=#{offset}-#{offset + part_size - 1}"
    )

    http_put() |> send_request(target_bucket_name, params, target_key, headers)
  end

  @doc """
  After finish all the task, complete multi_upload_file.
  """
  def complete_multipart_upload(bucket_name, key, upload_id, part_list, options \\ %{}) do
    headers = options
    params = %{ uploadId: upload_id }

    headers = if headers["user-metadata"] != nil do
      populate_headers_with_user_metadata(headers)
    else
      headers
    end
    part_list = Enum.map(part_list, fn item -> Map.put(item, "eTag", item["eTag"] |> String.replace("\"", "")) end)
    body = %{ parts: part_list }
    http_post() |> send_request(bucket_name, params, key, headers, body)
  end

  @doc """
  List all the parts that have been upload success.
  """
  def list_parts(bucket_name, key, upload_id, options \\ %{}) do
    params = Map.merge(%{ uploadId: upload_id }, options)
    http_get() |> send_request(bucket_name, params, key)
  end

  @doc """
  List all Multipart upload task which haven't been ended.(Completed Init_MultiPartUpload
  but not completed Complete_MultiPartUpload or Abort_MultiPartUpload).
  """
  def list_multipart_uploads(bucket_name, options \\ %{}) do
    params = Map.merge(%{ uploads: "" }, options)
    http_get() |> send_request(bucket_name, params)
  end

  @doc """
  Abort upload a part which is being uploading.
  """
  def abort_multipart_upload(bucket_name, key, upload_id) do
    params = %{ uploadId: upload_id }
    http_delete() |> send_request(bucket_name, params, key)
  end

  defp base_url, do: "http://#{ElixirBceSdk.config[:endpoint]}"
  defp base_url(bucket_name), do: "http://#{bucket_name}.#{ElixirBceSdk.config[:endpoint]}"

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

    headers = Enum.map(headers, fn{k,v} -> {k, Utils.to_s(v)} end) ++ [
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
        if return_body && res.status_code == 200 do
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

  defp populate_headers_with_user_metadata(%{"user-metadata" => %{} = user_metadata} = headers) do
    meta_size = 0
    {headers, meta_size} = Enum.reduce(user_metadata, {headers, meta_size},fn {k,v}, acc ->
      {headers, size} = acc
      k = Mbcs.encode!(k, :utf8)
      v = Mbcs.encode!(v, :utf8)
      normalized_key = http_bce_user_meta_data_prefix() <> k
      size = size + String.length(normalized_key)
      size = size + String.length(v)
      {Map.put(headers, normalized_key, v), size}
    end)
    if meta_size > bos_max_user_metadata_size() do
      raise BceClientException, message: "Metadata size should not be greater than #{bos_max_user_metadata_size()}"
    end
    Map.delete(headers, "user-metadata")
  end

  defp populate_headers_with_user_metadata(_) do
    raise BceClientException, message: "user_metadata should be of type map."
  end
end
