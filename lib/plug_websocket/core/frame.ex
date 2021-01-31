defmodule PlugWebsocket.Core.Frame do
  @type t ::
          {:ping, nil}
          | {:pong, nil}
          | {:text, payload :: binary()}
          | {:binary, payload :: binary()}
end
