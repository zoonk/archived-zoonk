defmodule Uneebee.Gamification do
  @moduledoc """
  This module is responsible for the gamification context.

  We use gamification to reward users for their actions and as a way to encourage them to keep learning.
  This context is responsible for managing everything that is related to gamification.
  """
  import Ecto.Query, warn: false
  import Uneebee.Gamification.UserMedal.Config

  alias Uneebee.Content
  alias Uneebee.Content.UserLesson
  alias Uneebee.Gamification.UserMedal
  alias Uneebee.Gamification.UserTrophy
  alias Uneebee.Repo

  @type user_medal_changeset :: {:ok, UserMedal.t()} | {:error, Ecto.Changeset.t()}
  @type user_trophy_changeset :: {:ok, UserTrophy.t()} | {:error, Ecto.Changeset.t()}

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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user medal changes.

  ## Examples

      iex> change_user_medal(%UserMedal{})
      %Ecto.Changeset{data: %UserMedal{}}
  """
  @spec change_user_medal(UserMedal.t(), map()) :: Ecto.Changeset.t()
  def change_user_medal(user_medal, attrs) do
    UserMedal.changeset(user_medal, attrs)
  end

  @doc """
  Creates a user medal.

  ## Examples

      iex> create_user_medal(%{field: value})
      {:ok, %UserMedal{}}
  """
  @spec create_user_medal(map()) :: user_medal_changeset()
  def create_user_medal(attrs) do
    %UserMedal{} |> change_user_medal(attrs) |> Repo.insert()
  end

  @doc """
  Returns the count of medals for a given user.

  ## Examples

      iex> count_user_medals(user_id)
      3
  """
  @spec count_user_medals(integer()) :: integer()
  def count_user_medals(user_id) do
    UserMedal |> where([um], um.user_id == ^user_id) |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of medals for a given user and medal type.

  ## Examples

      iex> count_user_medals(user_id, :bronze)
      3
  """
  @spec count_user_medals(integer(), atom()) :: integer()
  def count_user_medals(user_id, medal) do
    UserMedal |> where([um], um.user_id == ^user_id and um.medal == ^medal) |> Repo.aggregate(:count)
  end

  @doc """
  Awards a medal when a user completes a lesson.

  ## Examples

      iex> award_medal_for_lesson(%{user_id: 1, lesson_id: 1, perfect?: true, first_try?: true})
      {:ok, %UserMedal{}}
  """
  @spec award_medal_for_lesson(map()) :: user_medal_changeset()
  def award_medal_for_lesson(%{user_id: user_id, lesson_id: lesson_id, perfect?: true, first_try?: true}) do
    reason = :perfect_lesson_first_try
    medal = medal_type(reason)
    create_user_medal(%{user_id: user_id, lesson_id: lesson_id, medal: medal, reason: reason})
  end

  def award_medal_for_lesson(%{user_id: user_id, lesson_id: lesson_id, perfect?: true, first_try?: false}) do
    reason = :perfect_lesson_practiced
    medal = medal_type(reason)
    create_user_medal(%{user_id: user_id, lesson_id: lesson_id, medal: medal, reason: reason})
  end

  def award_medal_for_lesson(%{user_id: user_id, lesson_id: lesson_id, perfect?: false, first_try?: true}) do
    reason = :lesson_completed_with_errors
    medal = medal_type(reason)
    create_user_medal(%{user_id: user_id, lesson_id: lesson_id, medal: medal, reason: reason})
  end

  def award_medal_for_lesson(_attrs), do: nil

  @doc """
  Checks if this is the first lesson a user has completed today.

  ## Examples

      iex> first_lesson_today?(user_id)
      true
  """
  @spec first_lesson_today?(integer()) :: boolean()
  def first_lesson_today?(user_id) do
    UserLesson
    |> where([ul], ul.user_id == ^user_id)
    |> where([ul], fragment("date(?)", ul.updated_at) == ^Date.utc_today())
    |> limit(2)
    |> Repo.all()
    |> length()
    |> Kernel.==(1)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user trophy changes.

  ## Examples

      iex> change_user_trophy(%UserTrophy{})
      %Ecto.Changeset{data: %UserTrophy{}}
  """
  @spec change_user_trophy(UserTrophy.t(), map()) :: Ecto.Changeset.t()
  def change_user_trophy(user_trophy, attrs) do
    UserTrophy.changeset(user_trophy, attrs)
  end

  @doc """
  Creates a user trophy.

  ## Examples

      iex> create_user_trophy(%{field: value})
      {:ok, %UserTrophy{}}
  """
  @spec create_user_trophy(map()) :: user_trophy_changeset()
  def create_user_trophy(attrs) do
    %UserTrophy{} |> change_user_trophy(attrs) |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Maybe a award a trophy based on some parameters.

  ## Examples

      iex> maybe_award_trophy(%{})
      {:ok, %UserTrophy{}}
  """
  @spec maybe_award_trophy(map()) :: user_trophy_changeset()

  def maybe_award_trophy(%{user: user, course: course, course_completed?: true}) do
    create_user_trophy(%{user_id: user.id, course_id: course.id, reason: :course_completed})
  end

  def maybe_award_trophy(%{course_completed?: false}), do: {:ok, %UserTrophy{}}

  def maybe_award_trophy(%{user: user, course: course}) do
    maybe_award_trophy(%{user: user, course: course, course_completed?: Content.course_completed?(user, course)})
  end

  def maybe_award_trophy(_attrs), do: {:ok, %UserTrophy{}}

  @doc """
  Returns the count of trophies for a given user.

  ## Examples

      iex> count_user_trophies(user_id)
      3
  """
  @spec count_user_trophies(integer()) :: integer()
  def count_user_trophies(user_id) do
    UserTrophy |> where([ut], ut.user_id == ^user_id) |> Repo.aggregate(:count)
  end

  @doc """
  Get course completed trophy for a given user.

  ## Examples

      iex> get_course_completed_trophy(user_id, course_id)
      %UserTrophy{}

      iex> get_course_completed_trophy(user_id, course_id)
      nil
  """
  @spec get_course_completed_trophy(integer(), integer()) :: UserTrophy.t() | nil
  def get_course_completed_trophy(user_id, course_id) do
    UserTrophy
    |> where([ut], ut.user_id == ^user_id and ut.reason == :course_completed and ut.course_id == ^course_id)
    |> Repo.one()
  end
end
