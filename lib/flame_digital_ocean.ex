defmodule FlameDigitalOcean do
  @moduledoc """
  Documentation for `FlameDigitalOcean`.
  """

  @behaviour FLAME.Backend

  require Logger
  alias FlameDigitalOcean.{BackendState, Utils}

  @impl FLAME.Backend
  def init(opts) do
    # TODO
    app_config = Application.get_env(:flame, __MODULE__) || []
    {:ok, BackendState.new(opts, app_config)}
  end

  @impl FLAME.Backend
  def remote_boot(%BackendState{parent_ref: parent_ref} = state) do
    {resp, req_connect_time} =
      Utils.with_elapsed_ms(fn ->
        # TODO: Make a request to the DigitalOcean API to create a new machine

        # Placeholder for actual API call
        {nil, 0}
      end)

    Logger.info("#{inspect(__MODULE__)} #{inspect(node())} machine create #{req_connect_time}ms")

    remaining_connect_window = state.config.boot_timeout - req_connect_time

    case resp do
      %{"instance_id" => instance_id, "private_ip" => ip} ->
        new_state = %{
          state
          | runner_instance_id: instance_id,
            runner_instance_ip: ip
        }

        remote_terminator_pid =
          receive do
            {^parent_ref, {:remote_up, remote_terminator_pid}} ->
              remote_terminator_pid
          after
            remaining_connect_window ->
              Logger.error(
                "failed to connect to fly machine within #{state.config.boot_timeout}ms"
              )

              exit(:timeout)
          end

        new_state = %{
          new_state
          | remote_terminator_pid: remote_terminator_pid,
            runner_node_name: node(remote_terminator_pid)
        }

        {:ok, remote_terminator_pid, new_state}

      other ->
        {:error, other}
    end
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
    System.stop()
  end
end
