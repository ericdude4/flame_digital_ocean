defmodule FlameDigitalOcean do
  @moduledoc """
  Documentation for `FlameDigitalOcean`.
  """

  @behaviour FLAME.Backend

  alias FlameDigitalOcean.BackendState

  @impl FLAME.Backend
  def init(opts) do
    # TODO
    app_config = Application.get_env(:flame, __MODULE__) || []
    {:ok, BackendState.new(opts, app_config)}
  end

  @impl FLAME.Backend
  def remote_boot(state) do
    # TODO
  end

  @impl FLAME.Backend
  def remote_spawn_monitor(state, func) do
    # TODO
  end

  @impl FLAME.Backend
  def system_shutdown() do
    # TODO
  end
end
