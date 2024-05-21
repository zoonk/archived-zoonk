defmodule Zoonk.Repo.Migrations.AddRequireConfirmationFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :require_confirmation?, :boolean, default: false, null: false
    end
  end
end
