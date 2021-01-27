defmodule PlugWebsocket.Core.Message do
  @type t ::
          {:ping, nil}
          | {:pong, nil}
          | {:text, payload :: binary()}
          | {:binary, payload :: binary()}
end
