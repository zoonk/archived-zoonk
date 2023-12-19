defmodule UneebeeWeb.Billing.Utils do
  @moduledoc """
  Reusable configuration and utilities for billing.
  """

  import UneebeeWeb.Gettext

  @plan_features %{
    free: [
      dgettext("orgs", "2 users"),
      dgettext("orgs", "Unlimited lessons"),
      dgettext("orgs", "Custom logo"),
      dgettext("orgs", "Custom domain"),
      dgettext("orgs", "Cancel anytime")
    ],
    flexible: [
      dgettext("orgs", "Everything in Hobby"),
      dgettext("orgs", "Unlimited users"),
      dgettext("orgs", "Faster support")
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
        description: dgettext("orgs", "Dedicated support and infrastructure for your organization."),
        features: @plan_features[:enterprise]
      }
    ]
  end

  @spec currency_symbol(atom()) :: String.t()
  def currency_symbol(currency_code) do
    currency_code |> Atom.to_string() |> String.upcase() |> Money.Currency.symbol()
  end
end
