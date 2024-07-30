defmodule Zoonk.Repo.Migrations.ChangeAnswerToList do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :temp_answer, {:array, :string}
    end

    execute "UPDATE user_selections SET temp_answer = ARRAY[answer]"

    alter table(:user_selections) do
      remove :answer
    end

    rename table(:user_selections), :temp_answer, to: :answer
  end
end
