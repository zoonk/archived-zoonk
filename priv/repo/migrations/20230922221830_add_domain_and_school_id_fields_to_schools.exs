defmodule Zoonk.Repo.Migrations.AddDomainAndSchoolIdFieldsToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :custom_domain, :citext
      add :school_id, references(:schools, on_delete: :delete_all)
    end

    create index(:schools, [:school_id])
  end
end
