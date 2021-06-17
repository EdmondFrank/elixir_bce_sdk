defmodule ElixirBceSdk.Auth.BceCredentials do
  @moduledoc """
  module about authorization
  Reference https://cloud.baidu.com/doc/Reference/s/Njwvz1wot
  """
  alias ElixirBceSdk.Config
  alias ElixirBceSdk.Auth.BceCredentials
  defstruct [:access_key_id, :secret_access_key, :security_token]

  def new(access_key_id, secret_access_key, security_token \\ "") do
    %BceCredentials {
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      security_token: security_token,
    }
  end

  def credentials do
    %BceCredentials{
      access_key_id: Config.access_key_id(),
      secret_access_key: Config.secret_access_key(),
      security_token: Config.security_token()
    }
  end
end
