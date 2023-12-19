defmodule Uneebee.Billing do
  @moduledoc """
  Billing context.
  """

  alias Uneebee.Accounts.User
  alias Uneebee.Organizations
  alias Uneebee.Organizations.School

  @doc """
  Create a Stripe customer for a school.

  Returns the `stripe_customer_id` field in the school changeset.

  ## Examples

      iex> Billing.create_stripe_customer(%School{}, %User{})
      %School{stripe_customer_id: "cus_123"}
  """
  @spec create_stripe_customer(School.t(), User.t()) :: String.t()
  def create_stripe_customer(%School{stripe_customer_id: nil} = school, %User{} = manager) do
    case Stripe.Customer.create(%{email: manager.email, name: school.name, metadata: %{"school_id" => school.id, "user_id" => manager.id}}) do
      {:ok, %Stripe.Customer{} = customer} ->
        Organizations.update_school(school, %{stripe_customer_id: customer.id})
        customer.id

      {:error, error} ->
        raise error
    end
  end

  # Don't do anything if the school already has a Stripe customer.
  def create_stripe_customer(%School{} = school, _manager), do: school.stripe_customer_id
end
