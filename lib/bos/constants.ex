defmodule ElixirBceSdk.Bos.Constants do
  import Constants
  const :bos_min_part_number, 1
  const :bos_max_part_number, 10000
  const :bos_max_user_metadata_size, 2 * 1024
  const :bos_max_put_object_length, 5 * 1024 * 1024 * 1024
  const :bos_max_append_object_length, 5 * 1024 * 1024 * 1024
end
