defmodule Canvas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Loag board to persistent storage
    load_board()

    children = [
      Canvas.MonstersMem,
      Canvas.MonstersSupervisor,
      # CanvasWeb.Telemetry,
      # Canvas.Repo,
      {DNSCluster, query: Application.get_env(:canvas, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Canvas.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Canvas.Finch},
      # Start a worker by calling: Canvas.Worker.start_link(arg)
      # {Canvas.Worker, arg},
      # Start to serve requests, typically the last entry
      CanvasWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Canvas.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CanvasWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  alias Canvas.Board

  def load_board do
    {:ok, board} = Board.load_map("priv/static/board/chunk.tmj")
    :persistent_term.put(:board, board)
  end
end
