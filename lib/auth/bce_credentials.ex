defmodule ElixirBceSdk.Auth.BceCredentials do
  @moduledoc """
  module about authorization
  Reference https://cloud.baidu.com/doc/Reference/s/Njwvz1wot
  """
  alias ElixirBceSdk.Auth.BceCredentials
  defstruct access_key_id: nil, secret_access_key: nil, security_token: nil

  def new(access_key_id, secret_access_key, security_token \\ "") do
    %BceCredentials {
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      security_token: security_token,
    }
  end
end
