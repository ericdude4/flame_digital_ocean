defmodule FlameDigitalOcean.HTTPClient do
  @behaviour FlameDigitalOcean.HTTPClient.Behaviour

  alias FlameDigitalOcean.HttpClient.HTTPoisonAdapter

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def post(url, body, headers \\ [], options \\ []),
    do: impl().post(url, body, headers, options)

  defp impl, do: Application.get_env(:flame_digital_ocean, :http_client, HTTPoisonAdapter)
end
