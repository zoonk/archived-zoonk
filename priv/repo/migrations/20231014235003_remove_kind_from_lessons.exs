defmodule Zoonk.Repo.Migrations.RemoveKindFromLessons do
  use Ecto.Migration

  def change do
    alter table(:lessons) do
      remove :kind
    end
  end
end
