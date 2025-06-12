defmodule FlameDigitalOceanTest do
  use ExUnit.Case
  doctest FlameDigitalOcean

  describe "remote_boot/1" do
    setup do
      {:ok, backend_state} = FlameDigitalOcean.init([])

      {:ok, state: backend_state}
    end

    test "sends a request to digital ocean to boot a machine and updates state", %{
      state: backend_state
    } do
      Mox.expect(FlameDigitalOcean.HTTPClientMock, :post, 1, fn
        "https://api.digitalocean.com/v2/droplets", _body, _headers, _options ->
          {:ok,
           %{
             status_code: 202,
             body: %{"droplet" => %{"id" => 12345}}
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
