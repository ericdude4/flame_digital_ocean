defmodule FlameDigitalOcean.HTTPClient.Behaviour do
  @callback get(String.t()) :: {:ok, any()} | {:error, struct()}
  @callback get(String.t(), list()) :: {:ok, any()} | {:error, struct()}
  @callback get(String.t(), list(), keyword()) :: {:ok, any()} | {:error, struct()}

  @callback post(String.t(), any()) :: {:ok, any()} | {:error, struct()}
  @callback post(String.t(), any(), list()) :: {:ok, any()} | {:error, struct()}
  @callback post(String.t(), any(), list(), keyword()) :: {:ok, any()} | {:error, struct()}
end
