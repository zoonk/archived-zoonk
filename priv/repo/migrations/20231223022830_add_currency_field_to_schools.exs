defmodule Zoonk.Repo.Migrations.AddCurrencyFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :currency, :string
    end
  end
end
