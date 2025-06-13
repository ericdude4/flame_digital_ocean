defmodule FlameDigitalOceanTest do
  use ExUnit.Case
  doctest FlameDigitalOcean

  describe "remote_boot/1" do
    setup do
      {:ok, backend_state} = FlameDigitalOcean.init(boot_poll_interval: 0)

      {:ok, state: backend_state}
    end

    test "sends a request to digital ocean to boot a machine and updates state", %{
      state: backend_state
    } do
      FlameDigitalOcean.HTTPClientMock
      |> Mox.expect(:post, 1, fn
        "https://api.digitalocean.com/v2/droplets", _, _, _ ->
          {:ok,
           %{
             status_code: 202,
             body: Jason.encode!(%{"droplet" => %{"id" => 12345, "status" => "new"}})
           }}
      end)
      |> Mox.expect(:get, 1, fn "https://api.digitalocean.com/v2/droplets/12345", _, _ ->
        {:ok,
         %{
           status_code: 200,
           body: Jason.encode!(%{"droplet" => %{"id" => 12345, "status" => "new"}})
         }}
      end)
      |> Mox.expect(:get, 1, fn "https://api.digitalocean.com/v2/droplets/12345", _, _ ->
        {:ok,
         %{
           status_code: 200,
           body: Jason.encode!(%{"droplet" => %{"id" => 12345, "status" => "active"}})
         }}
      end)

      self = self()

      {_parent_ref, {:remote_up, terminator_pid}} =
        Task.async(fn ->
          # Give remote_boot a moment to reach its receive
          Process.sleep(50)
          send(self, {backend_state.parent_ref, {:remote_up, self()}})
        end)
        |> Task.await()

      assert {:ok, ^terminator_pid,
              %FlameDigitalOcean.BackendState{
                runner_env: %{
                  "FLAME_PARENT" => _,
                  "PHX_SERVER" => "false"
                },
                runner_instance_id: 12345,
                remote_terminator_pid: ^terminator_pid
              }} = FlameDigitalOcean.remote_boot(backend_state)
    end
  end
end
