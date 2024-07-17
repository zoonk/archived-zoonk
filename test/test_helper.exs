ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Zoonk.Repo, :manual)

# Mock the external storage API for tests
Mox.defmock(Zoonk.MockStorage, for: Zoonk.Storage)
Application.put_env(:zoonk, :s3, Zoonk.MockStorage)
