defmodule Uneebee.Repo.Migrations.AddMissionToUserTrophies do
  use Ecto.Migration

  def change do
    alter table(:user_trophies) do
      add :mission_id, references(:user_missions, on_delete: :delete_all)
    end

    create unique_index(:user_trophies, [:user_id, :mission_id])
  end
end
