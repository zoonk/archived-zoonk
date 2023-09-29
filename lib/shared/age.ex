defmodule UneebeeWeb.Shared.Age do
  @moduledoc """
  Utilies for managing a user's age.
  """

  @doc """
  Get a user's age giving a date of birth.

  ## Examples

      iex> UneebeeWeb.Shared.Age.age(~D[1990-01-01])
      30
  """
  @spec age(Date.t()) :: integer()
  def age(date_of_birth) do
    today = Date.utc_today()
    {:ok, birthday} = Date.new(today.year, date_of_birth.month, date_of_birth.day)
    diff = today.year - date_of_birth.year
    age(diff, Date.compare(birthday, today))
  end

  defp age(diff, :gt), do: diff - 1
  defp age(diff, _comparison), do: diff
end
