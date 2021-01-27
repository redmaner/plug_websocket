defmodule PlugWebsocket.Boundary.ChannelManager do
  require Logger
  use GenServer

  alias PlugWebsocket.Core.Channel

  def init(opts) do
    with {:ok, channels} <- Keyword.get(opts, :channels) |> check_channels() do
      Logger.info("WebStream server started with #{inspect(channels)}")
      {:ok, channels}
    else
      {:error, reason} ->
        raise reason
    end
  end

  defp check_channels(channels) when is_list(channels) do
    Enum.reduce_while(channels, {:ok, %{}}, fn channel, {:ok, acc} ->
      name = channel |> Keyword.get(:name)
      max_members = channel |> Keyword.get(:max_members) || 500

      case name do
        name when is_atom(name) ->
          new_channel = Channel.new(name, max_members)
          {:cont, {:ok, acc |> Map.put(name, new_channel)}}

        _ ->
          {:halt, {:error, "channel spec was invalid, name should be an atom"}}
      end
    end)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe_to_channel(member, channel) when is_pid(member) and is_atom(channel) do
    GenServer.call(__MODULE__, {:subscribe, member, channel})
  end

  def unsubscribe_from_channel(member, channel) when is_pid(member) and is_atom(channel) do
    GenServer.call(__MODULE__, {:unsubscribe, member, channel})
  end

  def handle_call(call, _from, state) do
    case call do
      {:subscribe, member, channel_name} ->
        handle_subscribe(member, channel_name, state)

      {:unsubscribe, member, channel_name} ->
        handle_unsubscribe(member, channel_name, state)
    end
  end

  defp handle_subscribe(member, channel_name, state) do
    subscribed? = Channel.subscribe_pid_to_channel(state[channel_name], member)

    case subscribed? do
      {:ok, new_channel} ->
        Logger.info(
          "PlugWebsocket::channel_manager | pid #{inspect(member)} subscribed to channel: #{
            channel_name
          }"
        )

        {:reply, :ok, state |> Map.put(channel_name, new_channel)}

      _error ->
        {:reply, subscribed?, state}
    end
  end

  defp handle_unsubscribe(member, channel_name, state) do
    {:ok, new_channel} = Channel.unsubscribe_pid_to_channel(state[channel_name], member)

    Logger.info(
      "PlugWebsocket::channel_manager | pid #{inspect(member)} unsubscribed from channel: #{
        channel_name
      }"
    )

    {:reply, :ok, state |> Map.put(channel_name, new_channel)}
  end
end
