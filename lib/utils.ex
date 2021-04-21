defmodule ElixirBceSdk.Utils do

  @moduledoc """
  module about some utility functions
  """
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
end
