defmodule ElixirBceSdk do
  @moduledoc """
  This is a simple client library for bce/bos
  Documentation for Baidu Cloud Bos
  """

  # @doc """
  # Get configuration
  # """
  # def config do
  #   Keyword.merge(default_config(), Application.get_env(:elixir_bce_sdk, :config, []))
  # end

  # defp default_config do
  #   [
  #     user_agent: "bce-elixir-sdk/#{MixProject.project[:version]}"
  #   ]
  # end

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: ElixirBceSdk.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ElixirBceSdk.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
