defmodule ElixirBceSdk.Utils do

  @moduledoc """
  module about some utility functions
  """
  def to_s_down(s), do: s |> to_string |> String.downcase
  def to_s_trim(s), do: s |> to_string |> String.trim
  def urlencode(s), do: s |> URI.encode(&URI.char_unreserved?(&1))
  def to_s_encode(s), do: s |> to_string |> urlencode
  def to_s_down_encode(s), do: s |> to_s_down |> urlencode
  def to_s_trim_encode(s), do: s |> to_s_trim |> urlencode

  def get_md5_from_file(file_name, content_length, buf_size \\ 8192) do
    File.stream!(file_name, [], buf_size)
    |> Enum.reduce(:crypto.hash_init(:md5), fn(line, acc) -> :crypto.hash_update(acc, line) end)
    |> :crypto.hash_final
    |> Base.encode64
  end
end
