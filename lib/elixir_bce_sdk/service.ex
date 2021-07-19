defmodule ElixirBceSdk.Service do
  alias ElixirBceSdk.Client
  import ElixirBceSdk.Config, only: [endpoint: 0]


  def get(bucket, object, opts \\ []) do
    request("GET", bucket, object, "", opts)
  end

  def put(bucket, object, body, opts \\ []) do
    request("PUT", bucket, object, body, opts)
  end

  def delete(bucket, object, opts \\ []) do
    request("DELETE", bucket, object, "", opts)
  end

  def head(bucket, object, opts \\ []) do
    request("HEAD", bucket, object, "", opts)
  end

  def post(bucket, object, body, opts \\ []) do
    request("POST", bucket, object, body, opts)
  end

  defp request(verb, bucket, object, body, opts) do
    {host, resource} =
      case bucket do
        <<_, _::binary>> -> {"#{bucket}.#{endpoint()}", "/#{bucket}/#{object}"}
        _ -> {endpoint(), "/"}
      end

    Client.request(
      %{
        http_method: verb,
        host: host,
        body: body,
        path: "/#{object}",
        resource: resource,
        params: Keyword.get(opts, :params, %{}),
        headers: Keyword.get(opts, :headers, %{}),
        save_path: Keyword.get(opts, :save_path, nil),
        return_body: Keyword.get(opts, :return_body, false),
      }
    )
  end
end
