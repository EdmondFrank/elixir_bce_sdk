defmodule ElixirBceSdk.Utils do

  @moduledoc """
  module about some utility functions
  """
  @bos_max_user_metadata_size 2 * 1024

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  def to_s(s) when is_map(s), do: Poison.encode!(s)
  def to_s(s), do: to_string(s)

  def to_s_down(s) when is_map(s), do: Poison.encode!(s) |> String.downcase()
  def to_s_down(s), do: to_string(s) |> String.downcase()

  def to_s_trim(s) when is_map(s), do: Poison.encode!(s) |> String.trim()
  def to_s_trim(s), do: to_string(s) |> String.trim()

  def urlencode(s), do: URI.encode(s, &URI.char_unreserved?(&1))

  def to_s_encode(s) when is_map(s), do: Poison.encode!(s) |> urlencode()
  def to_s_encode(s), do: to_string(s) |> urlencode()
  def to_s_down_encode(s), do: to_s_down(s) |> urlencode()
  def to_s_trim_encode(s), do: to_s_trim(s) |> urlencode()

  def get_md5_from_file(file_name, buf_size \\ 8192) do
    File.stream!(file_name, [], buf_size)
    |> Enum.reduce(:crypto.hash_init(:md5), fn(line, acc) -> :crypto.hash_update(acc, line) end)
    |> :crypto.hash_final()
    |> Base.encode64()
  end

  def populate_headers_with_user_metadata(%{"user-metadata" => %{} = user_metadata} = headers) do
    meta_size = 0
    {headers, meta_size} = Enum.reduce(user_metadata, {headers, meta_size},fn {k,v}, acc ->
      {headers, size} = acc
      k = Mbcs.encode!(k, :utf8)
      v = Mbcs.encode!(v, :utf8)
      normalized_key = "x-bce-meta-" <> k
      size = size + String.length(normalized_key)
      size = size + String.length(v)
      {Map.put(headers, normalized_key, v), size}
    end)
    if meta_size > @bos_max_user_metadata_size do
      raise BceClientException, message: "metadata size should not be greater than #{@bos_max_user_metadata_size}"
    end
    Map.delete(headers, "user-metadata")
  end
end
