defmodule Zoonk.Repo.Migrations.AddCorrectTotalFieldsToUserSelections do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :correct, :integer, default: 1
      add :total, :integer, default: 1
    end
  end
end
