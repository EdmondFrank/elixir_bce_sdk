defmodule BceSignerSpec do
  use ESpec

  alias ElixirBceSdk.Auth.BceSigner

  it "get canonical headers" do
    headers = %{ "host" => "xxx.xxx.xxx.xxx", "content-length" => 10, "x-bce-a" => "test" }
    { canonical_headers, headers_array } = BceSigner.get_canonical_headers(headers, nil)

    expect(canonical_headers) |> to(eq("content-length:10\nhost:xxx.xxx.xxx.xxx\nx-bce-a:test"))
    expect(headers_array) |> to(eq(["content-length", "host", "x-bce-a"]))
  end

  it "get canonical uri path" do
    path = "中文bucket/中文object"
    encoded_path = BceSigner.get_canonical_uri_path(path)
    expect(encoded_path) |> to(eq("/%E4%B8%AD%E6%96%87bucket/%E4%B8%AD%E6%96%87object"))

    path = "/bucket/object"

    encoded_path = BceSigner.get_canonical_uri_path(path)
    expect(encoded_path) |> to(eq("/bucket/object"))
  end

end
