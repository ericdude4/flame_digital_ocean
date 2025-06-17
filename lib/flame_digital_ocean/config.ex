defmodule FlameDigitalOcean.Config do
  @moduledoc false

  alias __MODULE__
  alias FlameDigitalOcean.Utils

  require Logger

  @valid_opts [
    :app,
    :name,
    :region,
    :size,
    :image,
    :ssh_keys,
    :backups,
    :backup_policy,
    :ipv6,
    :monitoring,
    :tags,
    :user_data,
    :volumes,
    :vpc_uuid,
    :with_droplet_agent,
    :boot_timeout,
    :boot_poll_interval,
    :env,
    :api_key,
    :erlang_cookie,
    :log,
    :host,
    :terminator_sup,
    :name_prefix
  ]

  @derive {Inspect,
           only: [
             :app,
             :name,
             :region,
             :size,
             :image,
             :backups,
             :backup_policy,
             :ipv6,
             :monitoring,
             :tags,
             :user_data,
             :volumes,
             :vpc_uuid,
             :with_droplet_agent,
             :boot_timeout,
             :boot_poll_interval,
             :log,
             :host,
             :name_prefix
           ]}

  defstruct app: nil,
            name: nil,
            region: nil,
            size: nil,
            image: nil,
            ssh_keys: nil,
            backups: false,
            backup_policy: nil,
            ipv6: false,
            monitoring: false,
            tags: [],
            user_data: nil,
            volumes: [],
            vpc_uuid: nil,
            with_droplet_agent: false,
            boot_timeout: nil,
            boot_poll_interval: 1_000,
            env: %{},
            api_key: nil,
            log: true,
            host: nil,
            erlang_cookie: nil,
            name_prefix: nil

  def new(opts, config) do
    default = %Config{
      app: System.get_env("RELEASE_NAME"),
      name: "#{opts[:name_prefix]}-flame-runner-#{Utils.rand_id(20)}",
      boot_timeout: 120_000,
      host: "https://api.digitalocean.com/v2"
    }

    provided_opts =
      config
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    Map.merge(default, Map.new(provided_opts))
  end
end
