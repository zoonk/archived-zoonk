defmodule Uneebee.Fixtures.Billing do
  @moduledoc """
  This module defines test helpers for creating entities via the `Uneebee.Billing` context.
  """

  import Uneebee.Fixtures.Organizations

  alias Uneebee.Billing
  alias Uneebee.Billing.Subscription

  @doc """
  Generate a subscription with valid attributes.
  """
  @spec valid_subscription_attributes(map()) :: map()
  def valid_subscription_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      payment_status: :pending,
      plan: :flexible,
      school_id: school_fixture().id,
      stripe_subscription_id: "sub_123"
    })
  end

  @doc """
  Generate a subscription.
  """
  @spec subscription_fixture(map()) :: Subscription.t()
  def subscription_fixture(attrs \\ %{}) do
    {:ok, %Subscription{} = subscription} = attrs |> valid_subscription_attributes() |> Billing.create_subscription()
    subscription
  end
end
