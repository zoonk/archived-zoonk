defmodule Uneebee.Repo.Migrations.AddStripeSubscriptionItemIdToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :stripe_subscription_item_id, :string
    end
  end
end
