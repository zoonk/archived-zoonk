defmodule Zoonk.Repo.Migrations.AddTermsAndPrivacyToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :privacy_policy, :string
      add :terms_of_use, :string
    end
  end
end
