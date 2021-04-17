defmodule ElixirBceSdk.Bos.Constants do
  import Constants
  const :bos_max_user_metadata_size, 2 * 1024
  const :bos_max_put_object_length, 5 * 1024 * 1024 * 1024
  const :bos_max_append_object_length, 5 * 1024 * 1024 * 1024
end
