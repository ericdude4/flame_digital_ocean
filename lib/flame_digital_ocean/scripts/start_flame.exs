File.cd!(System.user_home!())

flame_parent = System.fetch_env!("FLAME_PARENT") |> Base.decode64!() |> :erlang.binary_to_term()

%{
  pid: parent_pid,
  flame_vsn: flame_parent_vsn,
  backend_app: backend_app,
  backend_vsn: backend_vsn,
  ref: parent_ref
} = flame_parent

Path.wildcard("./flame_deps/flame/_build/dev/lib/*/ebin")
|> Enum.each(&Code.append_path/1)

Application.ensure_all_started(:flame)

flame_parent_node_name =
  "FLAME_PARENT_NODE_NAME"
  |> System.fetch_env!()
  |> String.to_atom()

Node.connect(flame_parent_node_name)

send(parent_pid, {parent_ref, {:remote_up, self()}})

System.no_halt(true)
