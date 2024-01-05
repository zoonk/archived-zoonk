defmodule Uneebee.Repo.Migrations.AddAnswerAndStepIdFieldsToUserSelections do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :answer, :text
      add :step_id, references(:lesson_steps, on_delete: :delete_all)
    end
  end
end
