defmodule Uneebee.Billing do
  @moduledoc """
  Billing context.
  """

  alias Uneebee.Accounts.User
  alias Uneebee.Billing.Subscription
  alias Uneebee.Organizations
  alias Uneebee.Organizations.School
  alias Uneebee.Repo

  @type subscription_changeset :: {:ok, Subscription.t()} | {:error, Ecto.Changeset.t()}

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

  @doc """
  Create a subscription for a school.

  ## Examples

      iex> Billing.create_subscription(%{school_id: 1, plan: :flexible})
      {:ok, %Subscription{}}
  """
  @spec create_subscription(map()) :: subscription_changeset()
  def create_subscription(attrs) do
    %Subscription{} |> Subscription.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Update a subscription.

  ## Examples

      iex> Billing.update_subscription(%Subscription{}, %{plan: :enterprise})
      {:ok, %Subscription{}}
  """
  @spec update_subscription(Subscription.t(), map()) :: subscription_changeset()
  def update_subscription(subscription, attrs) do
    subscription |> Subscription.changeset(attrs) |> Repo.update()
  end

  @doc """
  Get a school's subscription.

  ## Examples

      iex> Billing.get_subscription(school_id)
      %Subscription{}

      iex> Billing.get_subscription(school_id)
      nil
  """
  @spec get_subscription_by_school_id(non_neg_integer()) :: Subscription.t() | nil
  def get_subscription_by_school_id(school_id) do
    Repo.get_by(Subscription, school_id: school_id)
  end
end
