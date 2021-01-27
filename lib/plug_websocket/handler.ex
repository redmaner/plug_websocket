defmodule PlugWebsocket.Handler do
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
        {:cowboy_websocket, req, state}
      end

      @doc false
      @impl true
      def websocket_init(state) do
        case PlugWebsocket.Boundary.ChannelManager.subscribe_to_channel(
               self(),
               unquote(channel_name)
             ) do
          :ok ->
            {:ok, state}

          {:error, reason} ->
            {:error, reason}
        end
      end

      @doc false
      @impl true
      def websocket_handle(message, state) do
        unquote(module).handle_message(message, state)
      end

      @doc false
      @impl true
      def websocket_info(info, state) do
        unquote(module).handle_info(info, state)
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

  @callback handle_message(message :: term(), state :: term()) ::
              {:reply, reply :: term(), new_state :: term()}

  @callback handle_info(info :: term(), state :: term()) ::
              {:reply, reply :: term(), new_state :: term()}

  @callback handle_disconnect(reason :: term(), req :: term(), state :: term()) :: reply :: term()
end
