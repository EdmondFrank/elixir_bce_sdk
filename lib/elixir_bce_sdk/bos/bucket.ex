defmodule ElixirBceSdk.Bos.Bucket do
  @moduledoc """
  Bucket related operations
  """
  alias ElixirBceSdk.Service
  alias ElixirBceSdk.Client.Response

  @content_type "Content-Type"
  @json_content_type "application/json; charset=utf-8"

  @doc """
  List buckets of user.
  returns all buckets owned by the user.
  """
  @spec list_buckets() :: {:error, Response.t()} | {:ok, Response.t()}
  def list_buckets() do
    Service.get(nil, nil)
  end

  @doc """
  Create bucket with specific name.
  """
  @spec create_bucket(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def create_bucket(bucket_name) do
    Service.put(bucket_name, nil, "")
  end

  @doc """
  Delete bucket with specific name.
  """
  @spec delete_bucket(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def delete_bucket(bucket_name) do
    Service.delete(bucket_name, nil)
  end

  @doc """
  Get a bucket info by specific name.
  """
  @spec get_bucket(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket(bucket_name) do
    Service.head(bucket_name, nil)
  end

  @doc """
  Check whether there is a bucket with specific name.
  """
  @spec bucket_exist?(String.t()) :: boolean()
  def bucket_exist?(bucket_name) do
    case get_bucket(bucket_name) do
      {:ok, %Response{status: code}} -> code == 200
      {:error, _} -> false
    end
  end

  @doc """
  Get the region which the bucket located in.
  returns region of the bucket(bj/gz/sz).
  """
  @spec get_bucket_location(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_location(bucket_name) do
    Service.get(bucket_name, nil, params: %{location: ""})
  end

  @doc """
  Get Access Control Level of bucket.
  """
  @spec get_bucket_acl(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_acl(bucket_name) do
    Service.get(bucket_name, nil, params: %{acl: ""})
  end

  @doc """
  Set Access Control Level of bucket by body.
  """
  @spec set_bucket_acl(String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def set_bucket_acl(bucket_name, acl) do
    Service.put(
      bucket_name,
      nil,
      Poison.encode!(%{accessControlList: acl}),
      params: %{acl: ""},
      headers: %{@content_type => @json_content_type}
    )
  end

  @doc """
  Set Access Control Level of bucket by headers.
  """
  @spec set_bucket_canned_acl(String.t(), String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def set_bucket_canned_acl(bucket_name, canned_acl) do
    Service.put(
      bucket_name,
      nil,
      "",
      params: %{acl: ""},
      headers: %{"x-bce-acl" => canned_acl}
    )
  end

  @doc """
  Get Bucket Lifecycle
  """
  @spec get_bucket_lifecycle(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_lifecycle(bucket_name) do
    Service.get(bucket_name, nil, params: %{lifecycle: ""})
  end

  @doc """
  Put Bucket Lifecycle
  """
  @spec put_bucket_lifecycle(String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_bucket_lifecycle(bucket_name, rules) do
    Service.put(
      bucket_name,
      nil,
      Poison.encode!(%{rule: rules}),
      params: %{lifecycle: ""},
      headers: %{@content_type => @json_content_type}
    )
  end

  @doc """
  Delete Bucket Lifecycle
  """
  @spec delete_bucket_lifecycle(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def delete_bucket_lifecycle(bucket_name) do
    Service.delete(bucket_name, nil, params: %{lifecycle: ""})
  end

  @doc """
  Get Bucket Storageclass.
  """
  @spec get_bucket_storageclass(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_storageclass(bucket_name) do
    Service.get(bucket_name, nil, params: %{storageClass: ""})
  end

  @doc """
  Put Bucket Storageclass
  """
  @spec put_bucket_storageclass(String.t(), String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_bucket_storageclass(bucket_name, storage_class) do
    Service.put(
      bucket_name,
      nil,
      Poison.encode!(%{storageClass: storage_class}),
      params: %{storageClass: ""},
      headers: %{@content_type => @json_content_type}
    )
  end

  @doc """
  Put Bucket Cors
  """
  @spec put_bucket_cors(String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_bucket_cors(bucket_name, cors_configuration) do
    Service.put(
      bucket_name,
      nil,
      Poison.encode!(%{corsConfiguration: cors_configuration}),
      params: %{cors: ""},
      headers: %{@content_type => @json_content_type}
    )
  end

  @doc """
  Get Bucket Cors.
  """
  @spec get_bucket_cors(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_cors(bucket_name) do
    Service.get(bucket_name, nil, params: %{cors: ""})
  end

  @doc """
  Delete Bucket Cors
  """
  @spec delete_bucket_cors(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def delete_bucket_cors(bucket_name) do
    Service.delete(bucket_name, nil, params: %{cors: ""})
  end

  @doc """
  Get Bucket Logging.
  """
  @spec get_bucket_logging(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_bucket_logging(bucket_name) do
    Service.get(bucket_name, nil, params: %{logging: ""})
  end

  @doc """
  Put Bucket Logging.
  """
  @spec put_bucket_logging(String.t(), String.t(), String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def put_bucket_logging(source_bucket, target_bucket, target_prefix \\ "") do
    Service.put(
      source_bucket,
      nil,
      Poison.encode!(%{targetBucket: target_bucket, targetPrefix: target_prefix}),
      params: %{logging: ""},
      headers: %{@content_type => @json_content_type}
    )
  end

  @doc """
  Delete Bucket Logging.
  """
  @spec delete_bucket_logging(String.t()) :: {:error, Response.t()} | {:ok, Response.t()}
  def delete_bucket_logging(bucket_name) do
    Service.delete(bucket_name, nil, params: %{logging: ""})
  end

  @doc """
  Get Object Information of bucket.
  """
  @spec list_objects(String.t(), map()) :: {:error, Response.t()} | {:ok, Response.t()}
  def list_objects(bucket_name, options \\ %{}) do
    params = Map.merge(%{ maxKeys: 1000 }, options)
    Service.get(bucket_name, nil, params: params)
  end
end
