File.cd!(System.user_home!())

flame_parent = System.fetch_env!("FLAME_PARENT") |> Base.decode64!() |> :erlang.binary_to_term()

IO.inspect(flame_parent, label: "FLAME parent")

%{
  pid: parent_pid,
  flame_vsn: flame_parent_vsn,
  backend: _backend,
  backend_app: backend_app,
  backend_vsn: backend_vsn,
  # node_base: node_base,
  # host_env: host_env,
  ref: parent_ref
} = flame_parent

Path.wildcard("./flame_deps/flame_digital_ocean/_build/dev/lib/*/ebin")
|> Enum.each(&Code.append_path/1)

Application.ensure_all_started(:flame_digital_ocean)

flame_parent_node_name =
  "FLAME_PARENT_NODE_NAME"
  |> System.fetch_env!()
  |> String.to_atom()

IO.inspect(flame_parent_node_name, label: "FLAME Parent Node Name")

Node.connect(flame_parent_node_name)

IO.inspect(parent_pid, label: "Parent PID")
IO.inspect(parent_ref, label: "Parent Reference")
IO.inspect(Node.self(), label: "Self node")
IO.inspect(Node.list(), label: "Connected nodes")

send(parent_pid, {parent_ref, {:remote_up, self()}})

IO.puts(
  "[Digital Ocean FLAME Child] starting in FLAME mode with parent: \#{inspect(parent_pid)}, backend: \#{inspect(backend_app)}"
)

System.no_halt(true)
