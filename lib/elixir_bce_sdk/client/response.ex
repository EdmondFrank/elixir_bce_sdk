defmodule ElixirBceSdk.Client.Response do
  @moduledoc """
  Internal module
  """
  alias ElixirBceSdk.Client.Response

  defstruct [:status, :headers, :data]

  @type t :: %Response{status: integer, headers: keyword data: map}

  def generate_response(response, return_body) do
    case response do
      { :ok, res } ->
        if return_body && res.status_code == 200 do
          res.body
        else
          case  Poison.decode(res.body) do
            { :ok, decode_body } -> { :ok, %Response{status: res.status_code, data: decode_body, headers: res.headers} }
            { :error, %{value: ""} } -> { :ok, %Response{status: res.status_code, data: nil, headers: res.headers} }
            { :error, _raw } -> { :ok, %Response{status: res.status_code, data: res.body, headers: res.headers} }
          end
        end
      { :error, reason } -> { :error, reason }
    end
  end

  def generate_file(response, save_path) do
    if save_path do
      case File.write(save_path, response) do
        :ok -> {:ok, "Response save file path: #{save_path}"}
        {:error, reason} -> { :error, reason }
      end
    else
      response
    end
  end
end
