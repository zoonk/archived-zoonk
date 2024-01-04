defmodule Uneebee.Repo.Migrations.AddStepAnswersTable do
  use Ecto.Migration

  def change do
    create table(:step_answers) do
      add :lesson_step_id, references(:lesson_steps, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :answer, :text

      timestamps(type: :utc_datetime_usec)
    end
  end
end
