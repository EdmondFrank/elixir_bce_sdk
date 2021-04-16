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
end
