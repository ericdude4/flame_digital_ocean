defmodule FlameDigitalOcean.HttpClient.HTTPoisonAdapter do
  @behaviour FlameDigitalOcean.HTTPClient.Behaviour

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def post(url, body, headers \\ [], options \\ []),
    do: HTTPoison.post(url, body, headers, options)

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def get(url, headers \\ [], options \\ []),
    do: HTTPoison.get(url, headers, options)
end
