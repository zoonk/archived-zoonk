defmodule ZoonkWeb.Billing.Utils do
  @moduledoc """
  Reusable configuration and utilities for billing.
  """

  import ZoonkWeb.Gettext

  @max_free_users 2

  @plan_features %{
    free: [
      dgettext("orgs", "%{count} users", count: @max_free_users),
      dgettext("orgs", "Unlimited lessons"),
      dgettext("orgs", "Custom logo"),
      dgettext("orgs", "Custom domain")
    ],
    flexible: [
      dgettext("orgs", "Everything in Hobby"),
      dgettext("orgs", "Unlimited users"),
      dgettext("orgs", "Faster support"),
      dgettext("orgs", "Cancel anytime")
    ],
    enterprise: [
      dgettext("orgs", "Everything in Flexible"),
      dgettext("orgs", "Discounted pricing for 1,000+ users"),
      dgettext("orgs", "Priority support"),
      dgettext("orgs", "Dedicated infrastructure *"),
      dgettext("orgs", "25% off add-ons")
    ]
  }

  @spec currency_options(list()) :: list()
  def currency_options(options) do
    Enum.map(options, fn {key, _value} -> {String.upcase(Atom.to_string(key)), Atom.to_string(key)} end)
  end

  @spec billing_plans() :: list()
  def billing_plans do
    [
      %{key: :free, name: dgettext("orgs", "Hobby"), description: dgettext("orgs", "Get started for free."), features: @plan_features[:free]},
      %{key: :flexible, name: dgettext("orgs", "Flexible"), description: dgettext("orgs", "Pay as you go."), features: @plan_features[:flexible]},
      %{
        key: :enterprise,
        name: dgettext("orgs", "Enterprise"),
        description: dgettext("orgs", "Priority support and dedicated infrastructure."),
        features: @plan_features[:enterprise]
      }
    ]
  end

  @spec billing_options() :: list()
  def billing_options do
    Enum.map(billing_plans(), fn %{key: key, name: name} -> {name, key} end)
  end

  @spec payment_options() :: list()
  def payment_options do
    [
      {dgettext("orgs", "Confirmed"), :confirmed},
      {dgettext("orgs", "Pending"), :pending},
      {dgettext("orgs", "Failed"), :error}
    ]
  end

  @spec currency_symbol(atom()) :: String.t()
  def currency_symbol(currency_code) do
    currency_code |> Atom.to_string() |> String.upcase() |> Money.Currency.symbol()
  end

  @spec max_free_users() :: non_neg_integer()
  def max_free_users, do: @max_free_users
end
