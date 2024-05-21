defmodule Zoonk.Repo.Migrations.AddSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :paid_at, :utc_datetime_usec
      add :payment_status, :string, default: "pending", null: false
      add :plan, :string, default: "free", null: false
      add :stripe_payment_intent_id, :string
      add :stripe_subscription_id, :string
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:subscriptions, [:school_id])
  end
end
