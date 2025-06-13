defmodule FlameDigitalOcean.HTTPClient do
  @behaviour FlameDigitalOcean.HTTPClient.Behaviour

  alias FlameDigitalOcean.HttpClient.HTTPoisonAdapter

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def post(url, body, headers \\ [], options \\ []),
    do: impl().post(url, body, headers, options)

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def get(url, headers \\ [], options \\ []),
    do: impl().get(url, headers, options)

  defp impl, do: Application.get_env(:flame_digital_ocean, :http_client, HTTPoisonAdapter)
end
