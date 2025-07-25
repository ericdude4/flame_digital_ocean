defmodule FlameDigitalOcean.BackendState do
  @moduledoc false

  require Logger

  alias __MODULE__
  alias FlameDigitalOcean.{Config, Utils}

  defstruct config: nil,
            runner_node_base: nil,
            runner_node_name: nil,
            parent_ref: nil,
            runner_env: nil,
            runner_instance_id: nil,
            remote_terminator_pid: nil

  def new(opts, app_config) do
    config = Config.new(opts, app_config)

    Logger.info("Initialized FlameDigitalOcean with config #{inspect(config)}")

    runner_node_base = "#{config.app}-flame-#{Utils.rand_id(20)}"
    parent_ref = make_ref()

    encoded_parent =
      parent_ref
      |> FLAME.Parent.new(self(), FlameDigitalOcean, runner_node_base, "INSTANCE_IP")
      |> FLAME.Parent.encode()

    runner_env = build_env(encoded_parent, config)
    Logger.info("FlameDigitalOcean runner environment for runners: #{inspect(runner_env)}")

    %BackendState{
      config: config,
      runner_node_base: runner_node_base,
      parent_ref: parent_ref,
      runner_env: runner_env
    }
  end

  defp build_env(encoded_parent, %Config{} = config) do
    %{"PHX_SERVER" => "false", "FLAME_PARENT" => encoded_parent}
    |> Map.merge(config.env)
    |> then(fn env ->
      if flags = System.get_env("ERL_AFLAGS") do
        Map.put_new(env, "ERL_AFLAGS", flags)
      else
        env
      end
    end)
    |> then(fn env ->
      if flags = System.get_env("ERL_ZFLAGS") do
        Map.put_new(env, "ERL_ZFLAGS", flags)
      else
        env
      end
    end)
  end
end
