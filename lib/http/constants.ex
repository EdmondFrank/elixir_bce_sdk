defmodule ElixirBceSdk.Http.Constants do
  import Constants

  const :http_bce_prefix, "x-bce"
  const :http_bce_acl, "x-bce-acl"
  const :http_bce_date, "x-bce-date"

  const :http_host, "Host"
  const :http_authorization, "Authorization"
  const :http_json_type, "application/json; charset=utf-8"
  const :http_octet_stream, "application/octet-stream"
  const :http_content_type, "Content-Type"
  const :http_content_md5, "Content-MD5"
  const :http_content_length, "Content-Length"
  const :http_user_agent, "User-Agent"
  const :http_range, "Range"

  const :http_put, "PUT"
  const :http_get, "GET"
  const :http_head, "HEAD"
  const :http_post, "POST"
  const :http_delete, "DELETE"
end
