defmodule PlugWebsocket.Core.Conn do
  alias PlugWebsocket.Core.Frame

  @type t :: %__MODULE__{
          pid: pid(),
          peer_addr: Conn.address()
        }

  defstruct ~w[pid peer_addr]a

  @type address :: {:inet.ip_address(), :inet.port_number()}

  @type reply ::
          {:reply, frame :: Frame.t(), conn :: t()}
          | {:noreply, conn :: t()}

  @spec new(pid(), address()) :: conn :: Conn.t()
  def new(pid, peer_address) do
    %__MODULE__{
      pid: pid,
      peer_addr: peer_address
    }
  end
end
