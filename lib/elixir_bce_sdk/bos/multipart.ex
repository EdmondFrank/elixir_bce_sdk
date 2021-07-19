defmodule ElixirBceSdk.Bos.Multipart do
  @moduledoc """
  Multipart related api
  """
  alias ElixirBceSdk.Utils
  alias ElixirBceSdk.Service
  alias ElixirBceSdk.Client.Response

  alias ElixirBceSdk.Auth.BceSigner

  @content_type "Content-Type"
  @content_length "Content-Length"
  @default_content_type "application/octet-stream"
  @bos_min_part_number 1
  @bos_max_part_number 10000
  @bos_max_put_object_length 5 * 1024 * 1024 * 1024
  # @json_content_type "application/json; charset=utf-8"

  @doc """
  Initialize multi_upload_file.
  """
  @spec initialize_multipart_upload(String.t(), String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def initialize_multipart_upload(bucket_name, key, options \\ %{}) do
    params = %{ uploads: "" } |> Map.merge(options)
    Service.post(bucket_name, key, "", params: params)
  end

  @doc """
  Upload a part
  """
  @spec upload_part(String.t(), String.t(), String.t(), integer(), integer(), binary(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def upload_part(bucket_name, key, upload_id, part_number, part_size, data, options \\ %{}) do

    params = %{ partNumber: part_number, uploadId: upload_id }

    if part_number < @bos_min_part_number || part_number > @bos_max_part_number do
      raise BceClientException, message: "invalid part_number#{part_number}, The valid range is from #{@bos_min_part_number} to #{@bos_max_part_number}"
    end

    if part_size > @bos_max_put_object_length do
      raise BceClientException, message: "single part length should be less than #{@bos_max_put_object_length}"
    end

    headers = Map.merge(options, %{ @content_length => part_size, @content_type => @default_content_type })

    Service.post(bucket_name, key, data, headers: headers, params: params)
  end


  @doc """
  Upload a part from file.
  """
  @spec upload_part_from_file(String.t(), String.t(), String.t(), integer(), integer(), String.t(), integer(), map()) :: {:error, any()} | {:ok, Response.t()}
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
  @spec upload_part_copy(String.t(), String.t(), String.t(), String.t(), String.t(),
    integer(), integer(), integer(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def upload_part_copy(source_bucket_name, source_key, target_bucket_name, target_key, upload_id,
    part_number, part_size, offset, options \\ %{}) do

    headers = options

    params = %{ partNumber: part_number, uploadId: upload_id }

    headers = if headers["user-metadata"] != nil do
      Utils.populate_headers_with_user_metadata(headers)
    else
      headers
    end

    headers = if headers["etag"] != nil do
      Map.put(headers, "x-bce-copy-source-if-match", headers['etag'])
    else
      headers
    end

    headers =
      headers
      |> Map.put("x-bce-copy-source", BceSigner.get_canonical_uri_path("/#{source_bucket_name}/#{source_key}"))
      |> Map.put("x-bce-copy-source-range", "bytes=#{offset}-#{offset + part_size - 1}")

    Service.put(target_bucket_name, target_key, "", headers: headers, params: params)
  end


  @doc """
  After finish all the task, complete multi_upload_file.
  """
  @spec complete_multipart_upload(String.t(), String.t(), String.t(), list(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def complete_multipart_upload(bucket_name, key, upload_id, part_list, options \\ %{}) do
    headers = options
    params = %{ uploadId: upload_id }

    headers = if headers["user-metadata"] != nil do
      Utils.populate_headers_with_user_metadata(headers)
    else
      headers
    end
    part_list = Enum.map(part_list, fn item -> Map.put(item, "eTag", item["eTag"] |> String.replace("\"", "")) end)
    body = %{ parts: part_list }
    Service.post(bucket_name, key, Poison.encode!(body), headers: headers, params: params)
  end

  @doc """
  List all the parts that have been upload success.
  """
  @spec list_parts(String.t(), String.t(), String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def list_parts(bucket_name, key, upload_id, options \\ %{}) do
    params = Map.merge(%{ uploadId: upload_id }, options)
    Service.get(bucket_name, key, params: params)
  end

  @doc """
  List all Multipart upload task which haven't been ended.(Completed Init_MultiPartUpload
  but not completed Complete_MultiPartUpload or Abort_MultiPartUpload).
  """
  @spec list_multipart_uploads(String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def list_multipart_uploads(bucket_name, options \\ %{}) do
    params = Map.merge(%{ uploads: "" }, options)
    Service.get(bucket_name, nil, params: params)
  end

  @doc """
  Abort upload a part which is being uploading.
  """
  @spec abort_multipart_upload(String.t(), String.t(), String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def abort_multipart_upload(bucket_name, key, upload_id) do
    params = %{ uploadId: upload_id }
    Service.delete(bucket_name, key, params: params)
  end
end
