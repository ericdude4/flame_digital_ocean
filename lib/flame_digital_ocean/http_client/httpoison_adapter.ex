defmodule FlameDigitalOcean.HttpClient.HTTPoisonAdapter do
  @behaviour FlameDigitalOcean.HTTPClient.Behaviour

  @impl FlameDigitalOcean.HTTPClient.Behaviour
  def post(url, body, headers \\ [], options \\ []),
    do: HTTPoison.post(url, body, headers, options)
end
