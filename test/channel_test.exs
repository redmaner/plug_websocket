defmodule PlugWebsocket.Test.Channel do
  use ExUnit.Case
  use PlugWebsocket.Test.Builder

  test "channel | new()" do
    assert build_channel() == %Channel{
             name: :test,
             max_members: 100,
             members: MapSet.new()
           }
  end

  test "channel | subscribe()" do
    {:ok, pid} = Agent.start(fn -> 1 end)
    channel = build_channel()

    assert Channel.subscribe_pid_to_channel(channel, pid) ==
             {:ok,
              %Channel{
                name: :test,
                max_members: 100,
                members: MapSet.new([pid])
              }}

    Process.exit(pid, :normal)
  end

  test "channel | subscribe() max_members reached" do
    {:ok, pid} = Agent.start(fn -> 1 end)
    channel = build_channel(max_members: 0)

    assert Channel.subscribe_pid_to_channel(channel, pid) == {:error, :max_members_reached}

    Process.exit(pid, :normal)
  end

  test "channel | unsubscribe()" do
    {:ok, pid} = Agent.start(fn -> 1 end)

    channel = build_channel()

    {:ok, channel} = Channel.subscribe_pid_to_channel(channel, pid)

    assert Channel.unsubscribe_pid_to_channel(channel, pid) ==
             {:ok,
              %Channel{
                name: :test,
                max_members: 100,
                members: MapSet.new()
              }}

    Process.exit(pid, :normal)
  end

  test "channel | publish_to_channel()" do
    {:ok, pid} = Agent.start(fn -> 1 end)

    channel = build_channel()

    assert Channel.publish_to_channel(channel, {:text, "Hello, from test"}) ==
             {:ok, {:text, "Hello, from test"}}

    Process.exit(pid, :normal)
  end

  test "channel | publish_to_member()" do
    {:ok, pid} = Agent.start(fn -> 1 end)

    assert Channel.publish_to_member(pid, {:text, "Hello, from test"}) ==
             {:ok, {:text, "Hello, from test"}}

    Process.exit(pid, :normal)
  end
end
