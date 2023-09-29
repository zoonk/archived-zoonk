defmodule Uneebee.Repo.Migrations.AddUserSelectionsTable do
  use Ecto.Migration

  def change do
    create table(:user_selections) do
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :option_id, references(:step_options, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:user_selections, [:lesson_id, :user_id])
  end
end
