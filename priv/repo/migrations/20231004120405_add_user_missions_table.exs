defmodule Zoonk.Repo.Migrations.AddUserMissionsTable do
  use Ecto.Migration

  def change do
    create table(:user_missions) do
      add :reason, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:user_missions, [:reason, :user_id])
    create index(:user_missions, [:user_id])
  end
end
