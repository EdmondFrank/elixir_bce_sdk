defmodule ElixirBceSdkTest do
  use ExUnit.Case
  doctest ElixirBceSdk

  test "greets the world" do
    assert ElixirBceSdk.hello() == :world
  end
end
