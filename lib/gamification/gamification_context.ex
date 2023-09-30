defmodule Uneebee.Gamification do
  @moduledoc """
  This module is responsible for the gamification context.

  We use gamification to reward users for their actions and as a way to encourage them to keep learning.
  This context is responsible for managing everything that is related to gamification.
  """
  import Ecto.Query, warn: false

  alias Uneebee.Content.UserLesson
  alias Uneebee.Repo

  @doc """
  Calculates the learning days for a given user.

  It returns the sum of days a user has completed a lesson.

  ## Examples

      iex> learning_days_count(user_id)
      3
  """
  @spec learning_days_count(integer()) :: integer()
  def learning_days_count(user_id) do
    UserLesson
    |> where([ul], ul.user_id == ^user_id)
    |> group_by([ul], fragment("DATE(?)", ul.inserted_at))
    |> order_by([ul], desc: fragment("DATE(?)", ul.inserted_at))
    |> select([ul], max(ul.inserted_at))
    |> Repo.all()
    |> length()
  end
end
