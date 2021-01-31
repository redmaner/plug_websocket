defmodule PlugWebsocket.Handler do
  alias PlugWebsocket.Core.{Conn, Frame}

  defmacro __using__(opts) do
    module = __CALLER__.module

    channel_name =
      opts
      |> Keyword.get(:channel)
      |> case do
        name when is_atom(name) ->
          name

        _ ->
          :default
      end

    quote do
      require Logger
      @behaviour :cowboy_websocket
      @behaviour PlugWebsocket.Handler

      @doc false
      def channel() do
        unquote(channel_name)
      end

      @doc false
      @impl true
      def init(req, state) do
        {:cowboy_websocket, req, %{peer: req.peer}, %{"idle_timeout" => 600_000}}
      end

      @doc false
      @impl true
      def websocket_init(state) do
        case PlugWebsocket.Boundary.ChannelManager.subscribe_to_channel(
               self(),
               unquote(channel_name)
             ) do
          :ok ->
            {:ok, PlugWebsocket.Core.Conn.new(self(), state.peer)}

          {:error, reason} ->
            {:error, reason}
        end
      end

      @doc false
      @impl true
      def websocket_handle(frame, state) do
        unquote(module).handle_frame(frame, state)
      end

      @doc false
      @impl true
      def websocket_info(info, state) do
        case info do
          {:deliver, message} ->
            {:reply, message, state}

          info ->
            unquote(module).handle_info(info, state)
        end
      end

      @doc false
      @impl true
      def terminate(reason, req, state) do
        :ok =
          PlugWebsocket.Boundary.ChannelManager.unsubscribe_from_channel(
            self(),
            unquote(channel_name)
          )

        unquote(module).handle_disconnect(reason, req, state)
      end
    end
  end

  @callback handle_frame(frame :: Frame.t(), conn :: Conn.t()) :: Conn.reply()

  @callback handle_info(info :: term(), conn :: Conn.t()) :: Conn.reply()

  @callback handle_disconnect(reason :: term(), req :: term(), state :: term()) :: reply :: term()
end
