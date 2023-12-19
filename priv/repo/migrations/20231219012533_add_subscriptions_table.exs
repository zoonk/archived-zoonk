defmodule Uneebee.Repo.Migrations.AddSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :paid_at, :utc_datetime_usec
      add :payment_status, :string, default: "pending"
      add :plan, :string, default: "free"
      add :stripe_payment_intent_id, :string
      add :stripe_session_id, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
