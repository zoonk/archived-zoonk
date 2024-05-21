defmodule Zoonk.Repo.Migrations.AddStripeCustomerIdFieldToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :stripe_customer_id, :string
    end
  end
end
