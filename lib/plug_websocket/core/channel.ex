defmodule PlugWebsocket.Core.Channel do
  @moduledoc false
  # PlugWebsocket.Core.Channel handles core interactions with channels
  # This is used by the PlugWebsocket.Boundary.ChannelManager and should
  # not be used directly.

  defstruct ~w[name members max_members]a

  @spec new(atom(), integer()) :: %__MODULE__{}
  def new(name, max_members) do
    %__MODULE__{
      name: name,
      max_members: max_members,
      members: MapSet.new()
    }
  end

  @spec subscribe_pid_to_channel(%__MODULE__{}, pid()) ::
          {:ok, new_channel :: %__MODULE__{}}
          | {:error, :max_members_reached}
  def subscribe_pid_to_channel(channel, member) do
    case MapSet.member?(channel.members, member) do
      true ->
        {:ok, channel}

      false ->
        add_pid_to_channel(channel, member, channel.max_members, channel.members |> MapSet.size())
    end
  end

  defp add_pid_to_channel(_channel, _member, max_members, current_members)
       when current_members >= max_members,
       do: {:error, :max_members_reached}

  defp add_pid_to_channel(channel, member, _max_members, _curent_members) do
    new_members = channel.members |> MapSet.put(member)
    {:ok, %__MODULE__{channel | members: new_members}}
  end

  @spec unsubscribe_pid_to_channel(%__MODULE__{}, pid()) ::
          {:ok, new_channel :: %__MODULE__{}}
  def unsubscribe_pid_to_channel(channel, member) do
    case MapSet.member?(channel.members, member) do
      true ->
        new_members = channel.members |> MapSet.delete(member)
        {:ok, %__MODULE__{channel | members: new_members}}

      false ->
        {:ok, channel}
    end
  end
end
