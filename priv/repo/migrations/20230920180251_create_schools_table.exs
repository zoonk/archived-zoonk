defmodule Zoonk.Repo.Migrations.CreateSchoolsTable do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :email, :citext, null: false
      add :logo, :string
      add :name, :string, null: false
      add :public?, :boolean, default: false, null: false
      add :slug, :citext, null: false

      add :created_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:schools, [:slug])
  end
end
