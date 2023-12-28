defmodule Uneebee.Repo.Migrations.AddIconFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :icon, :string
    end
  end
end
