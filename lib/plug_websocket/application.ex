defmodule PlugWebsocket.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: PlugWebsocket.Boundary.ChannelManager,
        start: {PlugWebsocket.Boundary.ChannelManager, :start_link, []}
      },
      {Task.Supervisor, name: PlugWebsocket.Boundary.MailMan}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
