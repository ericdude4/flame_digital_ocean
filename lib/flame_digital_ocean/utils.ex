defmodule FlameDigitalOcean.Utils do
  def with_elapsed_ms(func) when is_function(func, 0) do
    {micro, result} = :timer.tc(func)

    {result, div(micro, 1000)}
  end

  def rand_id(len) do
    len
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, len)
  end

  def poll(func, opts \\ []) when is_function(func, 0) do
    interval = Keyword.get(opts, :interval, 1000)
    timeout = Keyword.get(opts, :timeout, 10_000)
    deadline = :erlang.monotonic_time(:millisecond) + timeout
    do_poll(func, interval, deadline)
  end

  defp do_poll(func, interval, deadline) do
    case func.() do
      {:ok, _} = ok ->
        ok

      _ ->
        if :erlang.monotonic_time(:millisecond) > deadline do
          {:error, :timeout}
        else
          Process.sleep(interval)
          do_poll(func, interval, deadline)
        end
    end
  end

  @doc """
  Ensure that the digital ocean machine contains `iex` in the path, set in the .profile file.
  """
  def build_user_data(%FlameDigitalOcean.BackendState{runner_env: runner_env, config: config}) do
    """
    #!/bin/bash

    set -eo pipefail

    # === 0. Config ===
    export ERLANG_COOKIE="#{config.erlang_cookie}"
    export NODE_NAME="remote@$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"
    export DISTRIBUTION_PORT=9100
    export FLAME_PARENT_NODE_NAME="#{Node.self()}"
    export FLAME_PARENT=#{runner_env["FLAME_PARENT"]}
    export PHX_SERVER=#{runner_env["PHX_SERVER"]}

    export HOME="/root"

    source /root/.profile

    # === 4. Set Erlang cookie ===
    echo "$ERLANG_COOKIE" > ~/.erlang.cookie
    chmod 400 ~/.erlang.cookie
    chown root:root ~/.erlang.cookie

    # === 5. Open ports ===
    ufw allow 22/tcp
    ufw allow 4369/tcp
    ufw allow $DISTRIBUTION_PORT/tcp
    ufw --force enable

    # === 6. Generate FLAME boot script ===
    ssh-keyscan github.com >> /root/.ssh/known_hosts

    cat <<'EOF' > $HOME/start_flame.exs
      #{File.read!(Path.expand("./scripts/start_flame.exs", __DIR__))}
    EOF

    command -v iex

    # === 7. Start IEx node in distributed mode and run boot script ===
    cat <<'EOF' > $HOME/start_flame_node.sh
    #!/bin/bash
    exec iex --name $NODE_NAME --cookie $ERLANG_COOKIE \
      --erl "-kernel inet_dist_listen_min $DISTRIBUTION_PORT inet_dist_listen_max $DISTRIBUTION_PORT" \
      $HOME/start_flame.exs
    EOF

    chmod +x /root/start_flame_node.sh
    nohup /root/start_flame_node.sh > /root/flame_node.log 2>&1 &
    """
  end
end
