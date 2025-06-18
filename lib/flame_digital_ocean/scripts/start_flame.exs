File.cd!(System.user_home!())

Logger.configure_backend(:console, format: "[$level] $message\n")

flame_parent = System.fetch_env!("FLAME_PARENT") |> Base.decode64!() |> :erlang.binary_to_term()

%{
  pid: parent_pid,
  flame_vsn: flame_parent_vsn,
  ref: parent_ref
} = flame_parent

Mix.install(
  [
    {:flame, flame_parent_vsn},
    {:flame_test, git: "https://github.com/ericdude4/flame_test.git", branch: "master"}
  ],
  consolidate_protocols: false
)

flame_parent_node_name =
  "FLAME_PARENT_NODE_NAME"
  |> System.fetch_env!()
  |> String.to_atom()

Node.connect(flame_parent_node_name)

IO.inspect(Node.list(), label: "Connected Nodes")

FlameTest.simulate_work()

send(parent_pid, {parent_ref, {:remote_up, self()}})

System.no_halt(true)
