defmodule Zoonk.Repo do
  use Ecto.Repo,
    otp_app: :zoonk,
    adapter: Ecto.Adapters.Postgres
end
