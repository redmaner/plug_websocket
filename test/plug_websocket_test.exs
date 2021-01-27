defmodule PlugWebsocketTest do
  use ExUnit.Case
  doctest PlugWebsocket

  test "greets the world" do
    assert PlugWebsocket.hello() == :world
  end
end
