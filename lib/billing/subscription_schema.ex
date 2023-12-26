defmodule Uneebee.Billing.Subscription do
  @moduledoc """
  Subscription schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Organizations.School

  @type t :: %__MODULE__{}

  schema "subscriptions" do
    field :paid_at, :utc_datetime_usec
    field :payment_status, Ecto.Enum, values: [:pending, :error, :confirmed], default: :pending
    field :plan, Ecto.Enum, values: [:free, :flexible, :enterprise], default: :free
    field :stripe_payment_intent_id, :string
    field :stripe_subscription_id, :string
    field :stripe_subscription_item_id, :string

    belongs_to :school, School

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:paid_at, :payment_status, :plan, :stripe_payment_intent_id, :school_id, :stripe_subscription_id, :stripe_subscription_item_id])
    |> validate_required([:payment_status, :plan, :school_id])
    |> unique_constraint(:school_id)
  end
end
