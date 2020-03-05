defmodule Client.Listener do
  @moduledoc """
  监听方
  """

  require Logger
  use GenServer

  @port 1080

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(_args) do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: false, reuseaddr: true])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{@port}...")
    {:ok, %{socket: socket}}
  end

  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, sock} = :gen_tcp.accept(socket)

    pid1 = :poolboy.checkout(:worker)
    {:ok, pid2} = Client.LocalWorker.start(pid1, sock)
    :gen_tcp.controlling_process(sock, pid2)
    Client.RemoteWorker.bind_socket(pid1, sock)
    send(self(), :accept)
    {:noreply, state}
  end
end