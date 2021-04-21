defmodule ElixirBceSdk.Auth.BceCredentials do
  @moduledoc """
  module about authorization
  Reference https://cloud.baidu.com/doc/Reference/s/Njwvz1wot
  """
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
      access_key_id: ElixirBceSdk.config[:access_key_id],
      secret_access_key: ElixirBceSdk.config[:secret_access_key],
      security_token: ElixirBceSdk.config[:security_token]
    }
  end
end
