defmodule Zoonk.Repo.Migrations.AddAnalyticsToSchoolUsers do
  use Ecto.Migration

  def change do
    alter table(:school_users) do
      add :analytics?, :boolean, default: true, null: false
    end
  end
end
