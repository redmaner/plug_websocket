defmodule PlugWebsocket.Test.Builder do
  alias PlugWebsocket.Core.{Channel, Message}

  defmacro __using__(_opts) do
    quote do
      alias PlugWebsocket.Core.{Channel, Message}
      import PlugWebsocket.Test.Builder
    end
  end

  def build_channel(overrides \\ []) do
    opts =
      Keyword.merge(
        [
          name: :test,
          max_members: 100
        ],
        overrides
      )

    Channel.new(opts[:name], opts[:max_members])
  end
end
