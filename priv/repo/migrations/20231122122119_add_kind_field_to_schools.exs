defmodule Zoonk.Repo.Migrations.AddKindFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :kind, :string, default: "white_label", null: false
    end

    create constraint(:schools, :valid_kind,
             check: "kind in ('marketplace', 'saas', 'white_label')"
           )
  end
end
