ExUnit.start()

Mox.defmock(FlameDigitalOcean.HTTPClientMock, for: FlameDigitalOcean.HTTPClient.Behaviour)
Application.put_env(:flame_digital_ocean, :http_client, FlameDigitalOcean.HTTPClientMock)
