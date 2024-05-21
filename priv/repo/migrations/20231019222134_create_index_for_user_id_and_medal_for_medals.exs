defmodule Zoonk.Repo.Migrations.CreateIndexForUserIdAndMedalForMedals do
  use Ecto.Migration

  def change do
    create index(:user_medals, [:user_id, :medal])
    create index(:user_medals, [:user_id, :medal, :reason])
  end
end
