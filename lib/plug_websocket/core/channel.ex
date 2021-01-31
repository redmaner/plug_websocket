defmodule PlugWebsocket.Core.Channel do
  @moduledoc false
  # PlugWebsocket.Core.Channel handles core interactions with channels
  # This is used by the PlugWebsocket.Boundary.ChannelManager and should
  # not be used directly.

  alias PlugWebsocket.Core.Frame

  @type t :: %__MODULE__{
          name: atom(),
          max_members: integer(),
          members: MapSet
        }

  defstruct ~w[name members max_members]a

  @spec new(atom(), integer()) :: Channel.t()
  def new(name, max_members) do
    %__MODULE__{
      name: name,
      max_members: max_members,
      members: MapSet.new()
    }
  end

  @spec subscribe_pid_to_channel(Channel.t(), pid()) ::
          {:ok, new_channel :: Channel.t()}
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

  @spec unsubscribe_pid_to_channel(Channel.t(), pid()) ::
          {:ok, new_channel :: Channel.t()}
  def unsubscribe_pid_to_channel(channel, member) do
    case MapSet.member?(channel.members, member) do
      true ->
        new_members = channel.members |> MapSet.delete(member)
        {:ok, %__MODULE__{channel | members: new_members}}

      false ->
        {:ok, channel}
    end
  end

  @spec publish_to_channel(channel :: Channel.t(), frame :: Frame.t()) ::
          {:ok, frame :: Frame.t()}
  def publish_to_channel(channel, frame) do
    Enum.each(channel.members, &publish_to_member(&1, frame))
    {:ok, frame}
  end

  @spec publish_to_member(member :: pid(), frame :: Frame.t()) ::
          {:ok, frame :: Frame.t()}
  def publish_to_member(member, frame) do
    Process.alive?(member)
    |> send_message(member, frame)

    {:ok, frame}
  end

  defp send_message(true, member, frame), do: send(member, {:deliver, frame})
  defp send_message(false, _member, _frame), do: :ok
end
