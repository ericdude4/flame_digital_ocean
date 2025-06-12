defmodule FlameDigitalOcean.HTTPClient.Behaviour do
  @callback post(String.t(), any()) :: {:ok, any()} | {:error, struct()}
  @callback post(String.t(), any(), list()) :: {:ok, any()} | {:error, struct()}
  @callback post(String.t(), any(), list(), keyword()) :: {:ok, any()} | {:error, struct()}
end
