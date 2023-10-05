defmodule Uneebee.Repo.Migrations.AddMissionToUserMedals do
  use Ecto.Migration

  def change do
    alter table(:user_medals) do
      add :mission_id, references(:user_missions, on_delete: :delete_all)
    end

    create unique_index(:user_medals, [:user_id, :mission_id])
  end
end
