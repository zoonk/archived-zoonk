defmodule Zoonk.Repo.Migrations.AddLanguageIndexToCourses do
  use Ecto.Migration

  def change do
    create index(:courses, [:public?, :published?, :language, :school_id])
    drop index(:courses, [:public?, :published?, :language])
  end
end
