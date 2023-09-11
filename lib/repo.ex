defmodule Uneebee.Repo do
  use Ecto.Repo,
    otp_app: :uneebee,
    adapter: Ecto.Adapters.Postgres
end
