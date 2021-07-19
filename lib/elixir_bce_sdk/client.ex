defmodule ElixirBceSdk.Client do
  @moduledoc """
  Internal module
  """
  alias ElixirBceSdk.Client.Request
  alias ElixirBceSdk.Client.Response

  def request(init_req) do
    req = Request.build_signed(init_req)
    req
    |> do_request()
    |> Response.generate_response(req.return_body)
    |> Response.generate_file(req.save_path)
  end

  defp do_request(req = %Request{http_method: "GET"}) do
    HTTPoison.get(
      Request.query_url(req),
      req.headers
    )
  end

  defp do_request(req = %Request{http_method: "HEAD"}) do
    HTTPoison.head(
      Request.query_url(req),
      req.headers
    )
  end

  defp do_request(req = %Request{http_method: "POST"}) do
    HTTPoison.post(
      Request.query_url(req),
      req.body,
      req.headers
    )
  end

  defp do_request(req = %Request{http_method: "PUT"}) do
    HTTPoison.put(
      Request.query_url(req),
      req.body,
      req.headers
    )
  end

  defp do_request(req = %Request{http_method: "DELETE"}) do
    HTTPoison.delete(
      Request.query_url(req),
      req.headers
    )
  end
end
