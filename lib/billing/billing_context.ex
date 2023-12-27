defmodule Uneebee.Billing do
  @moduledoc """
  Billing context.
  """

  import UneebeeWeb.Billing.Utils

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
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  @spec change_subscription(Subscription.t(), map()) :: Ecto.Changeset.t()
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  @doc """
  Create a subscription for a school.

  ## Examples

      iex> Billing.create_subscription(%{school_id: 1, plan: :flexible})
      {:ok, %Subscription{}}
  """
  @spec create_subscription(map()) :: subscription_changeset()
  def create_subscription(attrs) do
    %Subscription{} |> change_subscription(attrs) |> Repo.insert()
  end

  @doc """
  Update a subscription.

  ## Examples

      iex> Billing.update_subscription(%Subscription{}, %{plan: :enterprise})
      {:ok, %Subscription{}}
  """
  @spec update_subscription(Subscription.t(), map()) :: subscription_changeset()
  def update_subscription(subscription, attrs) do
    subscription |> change_subscription(attrs) |> Repo.update()
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

  @doc """
  Get the subscription price based on the lookup key set on Stripe.

  ## Examples

      iex> Billing.get_subscription_price(lookup_key)
      %Stripe.Price{}
  """
  @spec get_subscription_price(String.t()) :: any()
  def get_subscription_price(lookup_key) do
    {:ok, %Stripe.List{data: data}} = Stripe.Price.list(%{"limit" => 1, "lookup_keys" => [lookup_key], "type" => "recurring", "expand" => ["data.currency_options"]})
    price = Enum.at(data, 0)

    %{id: price.id, default: price.currency, currency_options: convert_currency_options(price.currency_options)}
  end

  defp convert_currency_options(currency_options) do
    Map.new(currency_options, fn {key, val} ->
      unit_amount = Map.get(val, :unit_amount, 0) / 100
      {key, unit_amount}
    end)
  end

  @doc """
  Delete a school subscription.

  ## Examples

      iex> Billing.delete_school_subscription(school_id)
      {:ok, %Subscription{}}
  """
  @spec delete_school_subscription(non_neg_integer()) :: subscription_changeset()
  def delete_school_subscription(school_id) do
    subscription = get_subscription_by_school_id(school_id)
    Stripe.Subscription.cancel(subscription.stripe_subscription_id)
    Repo.delete(subscription)
  end

  @doc """
  Check if a school has an active subscription.

  ## Examples

      iex> Billing.active_subscription?(%School{})
      true

      iex> Billing.active_subscription?(%School{})
      false
  """
  @spec active_subscription?(School.t()) :: boolean()
  def active_subscription?(%School{school_id: nil}), do: true
  def active_subscription?(%School{} = school), do: active_subscription?(school, get_subscription_by_school_id(school.id))
  defp active_subscription?(_school, %Subscription{payment_status: :confirmed}), do: true
  defp active_subscription?(%School{} = school, _subs), do: Organizations.get_school_users_count(school.id) <= max_free_users()

  @doc """
  Get Stripe's subscription item ID from a Stripe subscription ID.

  ## Examples

      iex> Billing.get_subscription_item_id(sub_123)
      "si_123"
  """
  @spec get_subscription_item_id(String.t()) :: String.t()
  def get_subscription_item_id(subscription_id) do
    {:ok, %Stripe.Subscription{items: items}} = Stripe.Subscription.retrieve(subscription_id)
    item = Enum.at(items.data, 0)
    item.id
  end
end
