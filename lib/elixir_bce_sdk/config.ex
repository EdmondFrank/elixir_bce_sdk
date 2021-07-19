defmodule ElixirBceSdk.Config do

  @version Mix.Project.config[:version]

  def version(), do: @version

  [:access_key_id, :secret_access_key, :security_token, :bucket_name, :endpoint]
  |> Enum.map(fn config ->
    def unquote(config)() do
      :elixir_bce_sdk
      |> Application.get_env(unquote(config))
      |> Confex.Resolver.resolve!()
    end
  end)
  def user_agent do
    "bce-elixir-sdk/#{version()}"
  end
end
