defmodule Uneebee.Repo.Migrations.AddGuestFieldToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :guest?, :boolean, default: false, null: false
    end
  end
end
