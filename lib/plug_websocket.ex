defmodule PlugWebsocket do
  require Logger

  def cowboy_child_spec(cowboy_opts, websocket_opts) do
    channels = websocket_opts |> Keyword.get(:channels)

    Logger.debug("channels: #{inspect(channels)}")

    plug = cowboy_opts |> Keyword.get(:plug)

    plug_opts =
      cowboy_opts
      |> Keyword.get(:options)
      |> Keyword.put(:dispatch, generate_dispatch(channels, plug))

    Plug.Cowboy.child_spec(cowboy_opts |> Keyword.put(:options, plug_opts))
  end

  defp generate_dispatch(channels, plug) do
    routes =
      Enum.reduce(channels, [], fn channel, acc ->
        # We extract the name of the channel
        name =
          channel
          |> Keyword.get(:name)
          |> case do
            name when is_atom(name) ->
              name

            _ ->
              raise "Channel name must be an atom"
          end

        # We extract the handler of the channel
        handler = channel |> Keyword.get(:handler)

        if handler.channel() != name do
          raise "Handler doesn't match given channel: #{name}"
        end

        # We extract the path of the channel handler
        path =
          channel
          |> Keyword.get(:path)
          |> case do
            path when is_binary(path) ->
              path

            _ ->
              raise "Path should be string"
          end

        acc ++ [{path, handler, []}]
      end)

    [
      {:_, routes ++ [{:_, plug, []}]}
    ]
  end

  def channel_manager_child_spec(opts) do
    %{
      id: PlugWebsocket.Boundary.ChannelManager,
      start: {PlugWebsocket.Boundary.ChannelManager, :start_link, [opts]}
    }
  end
end
