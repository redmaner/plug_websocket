defmodule PlugWebsocket.Handler do
  @moduledoc """
  `PlugWebsocket.Handler` provides various abstractions to handle Websocket frames received from clients.
  """

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
      import PlugWebsocket.Handler
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

  @doc """
  `handle_frame` is a callback function to handle Websocket frames. This function receives
  a Websocket frame, and a websocket connection. It should return a connection reply.
  """
  @callback handle_frame(frame :: Frame.t(), conn :: Conn.t()) :: Conn.reply()

  @doc """
  `handle_frame` is a callback function to handle info messages, similar to `GenServer` handle_info callbacks.
  """
  @callback handle_info(info :: term(), conn :: Conn.t()) :: Conn.reply()

  @doc """
  `handle_disconnect` allows a callback to handle a disconnect from the websocket server.
  """
  @callback handle_disconnect(reason :: term(), req :: term(), state :: term()) :: reply :: term()

  @doc """
  `reply` is a convenience function to reply to a Websocket frame or info. It takes a Websocket frame.
  """
  @spec reply(frame :: Frame.t(), conn :: Conn.t()) :: repsonse :: Conn.reply()
  def reply(frame, conn) do
    {:reply, frame, conn}
  end

  @doc """
  `reply_binary` is a convenience function to reply to a Websocket frame or info, with a binary frame.
  It will create the binary frame for you, using the provided binary as input.
  """
  @spec reply_binary(binary :: binary(), conn :: Conn.t()) :: Conn.reply()
  def reply_binary(binary, conn) do
    {:reply, {:binary, binary}, conn}
  end

  @doc """
  `reply_text` is a convenience function to reply to a Websocket frame or info, with a text frame.
  It will create the text frame for you, using the provided text as input.
  """
  @spec reply_text(text :: String.t(), conn :: Conn.t()) :: Conn.reply()
  def reply_text(text, conn) do
    {:reply, {:text, text}, conn}
  end

  @doc """
  `noreply` is a convenience function to not reply to a Websocket frame or info.
  """
  @spec noreply(conn :: Conn.t()) :: response :: Conn.reply()
  def noreply(conn) do
    {:noreply, conn}
  end
end
