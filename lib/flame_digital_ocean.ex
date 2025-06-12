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
  def remote_spawn_monitor(%BackendState{} = state, term) do
    case term do
      func when is_function(func, 0) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, func)
        {:ok, {pid, ref}}

      {mod, fun, args} when is_atom(mod) and is_atom(fun) and is_list(args) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, mod, fun, args)
        {:ok, {pid, ref}}

      other ->
        raise ArgumentError,
              "expected a null arity function or {mod, func, args}. Got: #{inspect(other)}"
    end
  end

  @impl FLAME.Backend
  def system_shutdown() do
    # TODO
  end
end
