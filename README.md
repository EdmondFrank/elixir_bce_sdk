# ElixirBceSdk

Baidu Could Storage SDK for Elixir

## Support
- BOS
  - [X] Bucket API
  - [X] Object API
  - [ ] Coming soon

- BCM
  - [X] get_metric_data
  - [ ] put_metric_data

- Coming soon


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_bce_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_bce_sdk, "~> 0.2"}
  ]
end
```
Then run `$ mix deps.get`

- Config the BOS Credentials
```elixir
# config/config.exs

config :elixir_bce_sdk,
    access_key_id: "<your access_key_id>",
    secret_access_key: "<your secret_access_key>",
    bos_endpoint: "<bos endpoint (eg: su.bcebos.com)>",
    bcm_user_id: "<bcm user id>",
    bcm_endpoint: "<bcm endpoint (eg: bcm.su.baidubce.com)>"

config :elixir_bce_sdk, ElixirBceSdk.Client,
  timeout: 30_000
```

Or if you want to config them via run-time system environment variables:

```elixir
# config/config.exs

config :elixir_bce_sdk,
    access_key_id: {:system, "BOS_ACCESS_KEY_ID"},
    secret_access_key: {:system, "BOS_SECRET_ACCESS_KEY"},
    bos_endpoint: {:system, "BOS_ENDPOINT"},
    bcm_user_id:  {:system, "BCM_USER_ID"},
    bcm_endpoint: {:system, "BCM_ENDPOINT"}

config :elixir_bce_sdk, ElixirBceSdk.Client,
  timeout: {:system, "TIMEOUT"}
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixir_bce_sdk](https://hexdocs.pm/elixir_bce_sdk).

## Usage

### Bucket Api

List Buckets
```elixir
ElixirBceSdk.Bos.Bucket.list_buckets()
```

Create Bucket
```elixir
ElixirBceSdk.Bos.Bucket.create_bucket("bucket-name")
```

Delete Bucket
```elixir
ElixirBceSdk.Bos.Bucket.delete_bucket("bucket-name")
```

Check Bucket is exist?
```elixir
ElixirBceSdk.Bos.Bucket.bucket_exist?("bucket-name")
```

Get Bucket location
```elixir
ElixirBceSdk.Bos.Bucket.get_bucket_location("bucket-name")
# => {:ok, 200, %{"locationConstraint" => "su"}}
```

Get Access Control Level of Bucket
```elixir
ElixirBceSdk.Bos.Bucket.get_bucket_acl("bucket-name")
```

Set Access Control Level of Bucket by body

```elixir
acl = [
  %{
    "grantee" => [
    %{ "id" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" },
    %{ "id" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  ],
    "permission" => ["FULL_CONTROL"]
  }
]
ElixirBceSdk.Bos.Bucket.set_bucket_acl("bucket_name", acl)
```

Set Access Control Level of Bucket by headers

```elixir
ElixirBceSdk.Bos.Bucket.set_bucket_canned_acl("bucket-name", "public-read")
```

Get Bucket Lifecycle

```elixir
ElixirBceSdk.Bos.Bucket.get_bucket_lifecycle("bucket-name")
```

Put Bucket Lifecycle
```elixir
rule = [
  %{
    "id" => "rule-id",
    "status" => "enabled",
    "resource" => ["bucket/prefix/*"],
    "condition" => %{
      "time" => %{
      "dateGreaterThan" => "2016-09-07T00:00:00Z"
      }
    },
    "action" => %{
      "name" => "DeleteObject"
    }
  }
]
ElixirBceSdk.Bos.Bucket.put_bucket_lifecycle("bucket-name", rule)
```

Delete Bucket Lifecycle
```elixir
ElixirBceSdk.Bos.Bucket.delete_bucket_lifecycle("bucket-name")
```

Get Bucket Storageclass
```elixir
ElixirBceSdk.Bos.Bucket.get_bucket_storageclass("bucket-name")
```

Put Bucket Storageclass
```elixir
ElixirBceSdk.Bos.Bucket.put_bucket_storageclass("bucket-name", "COLD")
```


### Objects Api

Get Object Information of Bucket
```elixir
ElixirBceSdk.Bos.Bucket.list_objects("bucket-name")
```

Get object of Bucket

```elixir
ElixirBceSdk.Bos.Object.get_object("bucket-name", "object-key")
```

Get object to file
```elixir
ElixirBceSdk.Bos.Object.get_object_to_file("bucket-name", "object-key", "path/to/save")
```

Get mete of object
```elixir
ElixirBceSdk.Bos.Object.get_object_meta_data("bucket-name", "object-key")
```

Create object and put content of string to the object
```elixir
ElixirBceSdk.Bos.Object.put_object_from_string("bucket-name", "object-key", "string data")
```

Put object and put content of file to the object
```elixir
ElixirBceSdk.Bos.Object.put_object_from_file("bucket-name", "object-key", "path/to/file")
```

Delete Object
```elixir
ElixirBceSdk.Bos.Object.delete_object("bucket-name", "object-key")
```

Get object acl
```elixir
ElixirBceSdk.Bos.Object.get_object_acl("bucket-name", "object-key")
```

Set object acl by headers
```elixir
ElixirBceSdk.Bos.Object.set_object_canned_acl("bucket-name", "object-key", "public-read")
```

Delete object acl
```elixir
ElixirBceSdk.Bos.Object.delete_object_acl("bucket-name", "object-key")
```

See the [bos directory](lib/bos) for other features

### BCM Api

Get metric data
```elixir
# default get last 15 minues range metric data and `period_in_second` is 60
# please use `h ElixirBceSdk.Bcm.Client.get_metric_data` to know more
ElixirBceSdk.Bcm.Client.get_metric_data("BCE_BOS", "BucketObjectCount", "BucketId:maven-mirror")
```
