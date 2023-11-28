defmodule Uneebee.Repo.Migrations.AddAllowGuestsFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :allow_guests?, :boolean, default: false, null: false
    end
  end
end
