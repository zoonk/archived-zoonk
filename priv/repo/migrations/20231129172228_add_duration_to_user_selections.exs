defmodule Zoonk.Repo.Migrations.AddDurationToUserSelections do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :duration, :integer, null: false, default: 0
    end
  end
end
