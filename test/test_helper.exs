ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Zoonk.Repo, :manual)

# Mock the external storage API for tests
Mox.defmock(Zoonk.Storage.StorageAPIMock, for: Zoonk.Storage.StorageAPIBehaviour)
Application.put_env(:zoonk, :storage_api, Zoonk.Storage.StorageAPIMock)

Mox.allow(Zoonk.Storage.StorageAPIMock, self(), fn ->
  GenServer.whereis(Zoonk.FLAME.ImageOptimization)
end)
