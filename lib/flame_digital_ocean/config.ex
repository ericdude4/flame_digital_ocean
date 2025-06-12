defmodule FlameDigitalOcean.Config do
  @moduledoc false

  alias __MODULE__

  require Logger

  @valid_opts [
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
    :host,
    :terminator_sup
  ]

  @derive {Inspect,
           only: [
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
             :host
           ]}

  defstruct name: nil,
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
            host: nil

  def new(opts, config) do
    default = %Config{
      boot_timeout: 120_000,
      host: "https://api.digitalocean.com/v2/"
    }

    provided_opts =
      config
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    Map.merge(default, Map.new(provided_opts))
  end
end
