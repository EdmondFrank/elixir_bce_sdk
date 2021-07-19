defmodule ElixirBceSdk.Bos.Object do
  @moduledoc """
  Object related operations
  """
  alias ElixirBceSdk.Utils
  alias ElixirBceSdk.Config
  alias ElixirBceSdk.Service
  alias ElixirBceSdk.Client.Response

  alias ElixirBceSdk.Auth.BceSigner
  alias ElixirBceSdk.Auth.BceCredentials

  @content_md5 "Content-MD5"
  @content_type "Content-Type"
  @content_length "Content-Length"
  @default_content_type "application/octet-stream"
  @json_content_type "application/json; charset=utf-8"
  @bos_max_put_object_length 5 * 1024 * 1024 * 1024
  @bos_max_append_object_length 5 * 1024 * 1024 * 1024

  @doc """
  Get object of bucket.
  """
  @spec get_object(String.t(), String.t(), any(), atom(), boolean()) :: {:error, Response.t()} | {:ok, Response.t()}
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
        %{"Range" => "bytes=#{s}-#{e}"}
    end
    Service.get(bucket_name, key, headers: headers, save_path: save_path, return_body: return_body)
  end

  @doc """
  Get object as string
  """
  @spec get_object_as_string(String.t(), String.t(), any()) :: {:error, Response.t()} | {:ok, Response.t() | String.t()}
  def get_object_as_string(bucket_name, key, range \\ nil) do
    get_object(bucket_name, key, range)
  end

  @doc """
  Get object to file
  """
  @spec get_object_to_file(String.t(), String.t(), any(), any()) :: {:error, Response.t()} | {:ok, Response.t() | {:ok, String.t()}}
  def get_object_to_file(bucket_name, key, save_path, range \\ nil) do
    get_object(bucket_name, key, range, save_path, true)
  end

  @doc """
  Get mete of object
  """
  @spec get_object_meta_data(String.t(), String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_object_meta_data(bucket_name, key) do
    Service.head(bucket_name, key)
  end

  @doc """
  Put object to BOS.
  """
  @spec put_object(String.t(), String.t(), binary(), String.t(), integer(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_object(bucket_name, key, data, content_md5, content_length, options) do
    if content_length > @bos_max_put_object_length do
      raise BceClientException, message: "object length should be less than #{@bos_max_put_object_length}"
    else
      headers =
        Map.merge(%{@content_md5 => content_md5, @content_length => content_length}, options)
        |> Map.put_new(@content_type, @default_content_type)
      Service.put(bucket_name, key, data, headers: headers)
    end
  end

  @doc """
  Create object and put content of string to the object.
  """
  @spec put_object_from_string(String.t(), String.t(), binary(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_object_from_string(bucket_name, key, data, options \\ %{}) do
    data_md5 = :crypto.hash(:md5, data) |> Base.encode64
    put_object(bucket_name, key, data, data_md5, String.length(data), options)
  end

  @doc """
  Put object and put content of file to the object.
  """
  @spec put_object_from_file(String.t(), String.t(), String.t(), map()) :: {:error, any()} | {:ok, Response.t()}
  def put_object_from_file(bucket_name, key, file_name, options \\ %{}) do

    options = Map.put_new(options, @content_type, MIME.from_path(file_name))

    case File.read(file_name) do
      {:ok, data} ->
        content_length = byte_size(data)
        data_md5 = Utils.get_md5_from_file(file_name)
        put_object(bucket_name, key, data, data_md5, content_length, options)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get an authorization url with expire time
  """
  @spec generate_pre_signed_url(String.t(), String.t(), map()) :: String.t()
  def generate_pre_signed_url(bucket_name, key, opts \\ %{}) do

    params = Map.get(opts, :params, %{})
    host = "#{bucket_name}.#{Config.endpoint()}"
    path = "/" <> key
    headers = Map.get(opts, :headers, %{}) |> Map.put("Host", host)

    signture = BceSigner.sign(
      BceCredentials.credentials(),
      "GET",
      path,
      headers,
      params,
      opts[:timestamp],
      opts[:expiration_in_seconds] || 1800,
      opts[:headers_to_sign]
    )

    params = Map.put(params, "authorization", signture)

    URI.to_string(
      %URI{
        scheme: "https",
        host: host,
        path: path,
        query: BceSigner.get_canonical_querystring(params, false)
      }
    )
  end

  @doc """
  Copy one object to another object.
  """
  @spec copy_object(String.t(), String.t(), String.t(), String.t(), map()) :: Response.t()
  def copy_object(source_bucket_name, source_key, target_bucket_name, target_key, options \\ %{}) do

    headers = options

    headers = if headers["etag"] != nil do
      Map.put(headers, "x-bce-copy-source-if-match", headers["etag"])
    else
      headers
    end

    headers =
      case headers["user-metadata"] do
        nil ->
          Map.put(headers, "x-bce-metadata-directive", "copy")
        _ ->
          headers = Map.put(headers, "x-bce-metadata-directive", "replace")
          Utils.populate_headers_with_user_metadata(headers)
      end

    headers = Map.put(
      headers,
      "x-bce-copy-source",
      BceSigner.get_canonical_uri_path("/#{source_bucket_name}/#{source_key}")
    )

    Service.put(target_bucket_name, target_key, "", headers: headers)
  end

  @doc """
  Put an appendable object to BOS or add content to an appendable object.
  """
  @spec append_object(String.t(), String.t(), binary(), integer(), String.t(), integer(), map()) :: Response.t()
  def append_object(bucket_name, key, data, offset, content_md5, content_length, options \\ %{}) do
    if content_length > @bos_max_append_object_length do
      raise BceClientException, message: "object length should be less than #{@bos_max_append_object_length}. Use multi-part upload instead."
    end

    params = %{ append: "" }
    |> Utils.maybe_put(:offset, offset)

    headers = Map.merge(%{@content_md5 => content_md5, @content_length => content_length}, options)

    headers = if headers["user-metadata"] != nil do
      Utils.populate_headers_with_user_metadata(headers)
    else
      headers
    end

    Service.post(bucket_name, key, data, headers: headers, params: params)
  end

  @doc """
  Create an appendable object and put content of string to the object
  or add content of string to an appendable object.
  """
  @spec append_object_from_string(String.t(), String.t(), binary(), map()) :: Response.t()
  def append_object_from_string(bucket_name, key, data, options \\ %{}) do
    data_md5 = :crypto.hash(:md5, data) |> Base.encode64
    append_object(bucket_name, key, data, options["offset"], data_md5, String.length(data), options)
  end

  @doc """
  Delete Object
  """
  @spec delete_object(String.t(), String.t()) :: Response.t()
  def delete_object(bucket_name, key) do
    Service.delete(bucket_name, key)
  end

  @doc """
  Delete Multiple Objects.
  """
  @spec delete_multiple_objects(String.t(), list()) :: Response.t()
  def delete_multiple_objects(bucket_name, key_list) do
    params = %{ delete: "" }
    key_arr = Enum.map(key_list, fn item -> %{ key: item } end)
    body = %{ objects: key_arr }
    Service.post(bucket_name, nil, Poison.encode!(body), params: params)
  end

  @doc """
  Get object acl.
  """
  @spec get_object_acl(String.t(), String.t()) :: Response.t()
  def get_object_acl(bucket_name, key) do
    params = %{ acl: "" }
    Service.get(bucket_name, key, params: params)
  end

  @doc """
  Set object acl by body.
  """
  @spec set_object_acl(String.t(), String.t(), list()) :: Response.t()
  def set_object_acl(bucket_name, key, acl) do
    params = %{ acl: "" }
    headers = %{ @content_type => @json_content_type }
    body = %{ accessControlList: acl }
    Service.put(bucket_name, key, Poison.encode!(body), headers: headers, params: params)
  end

  @doc """
  Set object acl by headers.
  """
  @spec set_object_canned_acl(String.t(), String.t(), map()) :: Response.t()
  def set_object_canned_acl(bucket_name, key, canned_acl) do
    Service.put(bucket_name, key, "", headers: %{"x-bce-acl" => canned_acl}, params: %{ acl: "" })
  end

  @doc """
  Delete object acl.
  """
  @spec delete_object_acl(String.t(), String.t()) :: Response.t()
  def delete_object_acl(bucket_name, key) do
    Service.delete(bucket_name, key, params: %{ acl: "" })
  end
end
