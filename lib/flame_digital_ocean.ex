defmodule FlameDigitalOcean do
  @moduledoc """
  Documentation for `FlameDigitalOcean`.
  """

  @behaviour FLAME.Backend

  require Logger
  alias FlameDigitalOcean.{BackendState, HTTPClient, Utils}

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
        url = "#{state.config.host}/droplets"

        body =
          [
            {"name", state.config.name},
            {"region", state.config.region},
            {"size", state.config.size},
            {"image", state.config.image},
            {"ssh_keys", state.config.ssh_keys},
            {"backups", state.config.backups},
            {"backup_policy", state.config.backup_policy},
            {"ipv6", state.config.ipv6},
            {"monitoring", state.config.monitoring},
            {"tags", state.config.tags},
            {"user_data", state.config.user_data},
            {"volumes", state.config.volumes},
            {"vpc_uuid", state.config.vpc_uuid},
            {"with_droplet_agent", state.config.with_droplet_agent}
          ]
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> Map.new()
          |> Jason.encode()

        headers = [
          {"Authorization", "Bearer #{state.config.api_key}"},
          {"Content-Type", "application/json"}
        ]

        case HTTPClient.post(url, body, headers, []) do
          {:ok, %{status_code: 202, body: body}} ->
            resp = Jason.decode(body)

            case resp do
              {:ok, %{"droplet" => %{"id" => _droplet_id, "status" => "active"}}} ->
                resp

              {:ok, %{"droplet" => %{"id" => droplet_id, "status" => "new"}}} ->
                # Poll the droplet status until it's active
                Utils.poll(
                  fn ->
                    case HTTPClient.get("#{url}/#{droplet_id}", headers) do
                      {:ok, %{status_code: 200, body: body}} ->
                        case Jason.decode(body) do
                          {:ok, %{"droplet" => %{"id" => ^droplet_id, "status" => "active"}}} =
                              resp ->
                            resp

                          {:ok, %{"droplet" => %{"id" => ^droplet_id, "status" => status}}} ->
                            {:error, "Droplet is not active yet, current status: #{status}"}
                        end
                    end
                  end,
                  interval: state.config.boot_poll_interval,
                  timeout: state.config.boot_timeout
                )
            end
        end
      end)

    Logger.info("#{inspect(__MODULE__)} #{inspect(node())} machine create #{req_connect_time}ms")

    remaining_connect_window = state.config.boot_timeout - req_connect_time

    case resp do
      {:ok, %{"droplet" => %{"id" => droplet_id}}} ->
        new_state = %{state | runner_instance_id: droplet_id}

        remote_terminator_pid =
          receive do
            {^parent_ref, {:remote_up, remote_terminator_pid}} ->
              remote_terminator_pid
          after
            remaining_connect_window ->
              Logger.error(
                "failed to connect to digital ocean machine within #{state.config.boot_timeout}ms"
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
