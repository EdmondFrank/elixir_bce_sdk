defmodule ElixirBceSdk do
  alias ElixirBceSdk.MixProject
  @moduledoc """
  This is a simple client library for bce/bos
  """

  @doc """
  Get configuration
  """
  def config do
    Keyword.merge(default_config(), Application.get_env(:elixir_bce_sdk, :config, []))
  end

  defp default_config do
    [
      user_agent: "bce-elixir-sdk/#{MixProject.project[:version]}"
    ]
  end
end
