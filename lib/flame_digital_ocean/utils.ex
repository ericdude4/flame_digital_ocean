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
  def build_user_data(%FlameDigitalOcean.Config{} = config) do
    """
    #!/bin/bash

    set -eo pipefail

    # === 0. Config ===
    export ERLANG_COOKIE="#{config.erlang_cookie}"
    export NODE_NAME="remote@$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"
    export DISTRIBUTION_PORT=9100

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
    cat <<'EOF' > $HOME/start_flame.exs
    File.cd!(System.user_home!())

    flame_parent = System.fetch_env!("FLAME_PARENT") |> Base.decode64!() |> :erlang.binary_to_term()

    %{
      pid: parent_pid,
      flame_vsn: flame_parent_vsn,
      backend: _backend,
      backend_app: backend_app,
      backend_vsn: backend_vsn,
      node_base: node_base,
      host_env: host_env
    } = flame_parent

    flame_node_name = :"\#{node_base}@\#{System.fetch_env!(host_env)}"
    flame_node_cookie = String.to_atom(System.fetch_env!("FLAME_COOKIE"))

    flame_dep =
      if git_ref = System.get_env("FLAME_GIT_REF") do
        {:flame, github: "phoenixframework/flame", ref: git_ref}
      else
        {:flame, flame_parent_vsn}
      end

    flame_backend_deps =
      case backend_app do
        :flame -> []
        _ -> [{backend_app, backend_vsn}]
      end

    {:ok, _} = :net_kernel.start(flame_node_name, %{name_domain: :longnames})
    Node.set_cookie(flame_node_cookie)

    Mix.install([flame_dep | flame_backend_deps], consolidate_protocols: false)

    IO.puts(
      "[Livebook] starting \#{inspect(flame_node_name)} in FLAME mode with parent: \#{inspect(parent_pid)}, backend: \#{inspect(backend_app)}"
    )

    System.no_halt(true)
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
