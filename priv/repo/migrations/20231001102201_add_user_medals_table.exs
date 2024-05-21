defmodule Zoonk.Repo.Migrations.AddUserMedalsTable do
  use Ecto.Migration

  def change do
    create table(:user_medals) do
      add :medal, :string, null: false
      add :reason, :string, null: false

      add :lesson_id, references(:lessons, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec)
    end

    constraint(:user_medals, :valid_medal, check: "medal in ('bronze', 'silver', 'gold')")

    create index(:user_medals, [:user_id])
  end
end
