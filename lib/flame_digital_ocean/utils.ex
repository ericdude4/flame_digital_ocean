defmodule FlameDigitalOcean.Utils do
  def with_elapsed_ms(func) when is_function(func, 0) do
    {micro, result} = :timer.tc(func)

    {result, div(micro, 1000)}
  end

  def rand_id(len) do
    len
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, len)
  end

  def poll(func, opts \\ []) when is_function(func, 0) do
    interval = Keyword.get(opts, :interval, 1000)
    timeout = Keyword.get(opts, :timeout, 10_000)
    deadline = :erlang.monotonic_time(:millisecond) + timeout
    do_poll(func, interval, deadline)
  end

  defp do_poll(func, interval, deadline) do
    case func.() do
      {:ok, _} = ok ->
        ok

      _ ->
        if :erlang.monotonic_time(:millisecond) > deadline do
          {:error, :timeout}
        else
          Process.sleep(interval)
          do_poll(func, interval, deadline)
        end
    end
  end
end
