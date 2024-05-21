defmodule Zoonk.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :avatar, :string
      add :confirmed_at, :naive_datetime
      add :date_of_birth, :date
      add :email, :citext, null: false
      add :first_name, :string
      add :language, :string, null: false, default: "en"
      add :last_name, :string
      add :hashed_password, :string, null: false
      add :username, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
