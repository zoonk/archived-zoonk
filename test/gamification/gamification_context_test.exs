defmodule Uneebee.GamificationTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Gamification
  alias Uneebee.Gamification.UserMedal

  describe "learning_days_count/1" do
    test "calculates how many learning days a user has completed" do
      user = user_fixture()
      Enum.each(1..3, fn idx -> generate_user_lesson(user.id, -idx) end)
      assert Gamification.learning_days_count(user.id) == 3
    end
  end

  describe "create_user_medal/1" do
    test "creates a user medal" do
      user = user_fixture()
      attrs = %{user_id: user.id, medal: :gold, reason: :perfect_lesson_first_try}

      assert {:ok, %UserMedal{} = user_medal} = Gamification.create_user_medal(attrs)
      assert user_medal.user_id == attrs.user_id
      assert user_medal.medal == attrs.medal
      assert user_medal.reason == attrs.reason
      assert is_nil(user_medal.lesson_id)
    end

    test "creates a user medal with a lesson" do
      user = user_fixture()
      lesson = lesson_fixture()
      attrs = %{user_id: user.id, lesson_id: lesson.id, medal: :gold, reason: :perfect_lesson_first_try}

      assert {:ok, %UserMedal{} = user_medal} = Gamification.create_user_medal(attrs)
      assert user_medal.user_id == attrs.user_id
      assert user_medal.lesson_id == attrs.lesson_id
      assert user_medal.medal == attrs.medal
      assert user_medal.reason == attrs.reason
    end

    test "returns an error when the reason is invalid" do
      user = user_fixture()
      attrs = %{user_id: user.id, medal: :gold, reason: :invalid_reason}

      assert {:error, %Ecto.Changeset{} = changeset} = Gamification.create_user_medal(attrs)
      assert "is invalid" in errors_on(changeset).reason
    end

    test "returns an error when the medal is invalid" do
      user = user_fixture()
      attrs = %{user_id: user.id, medal: :invalid_medal, reason: :perfect_lesson_first_try}

      assert {:error, %Ecto.Changeset{} = changeset} = Gamification.create_user_medal(attrs)
      assert "is invalid" in errors_on(changeset).medal
    end
  end

  describe "count_user_medals/1" do
    test "returns the count of medals for a given user" do
      user = user_fixture()
      attrs = %{user_id: user.id, medal: :gold, reason: :perfect_lesson_first_try}
      Enum.each(1..3, fn _idx -> Gamification.create_user_medal(attrs) end)
      assert Gamification.count_user_medals(user.id) == 3
    end
  end

  describe "count_user_medals/2" do
    test "returns the count of medals for a given user and medal type" do
      user = user_fixture()

      attrs_gold = %{user_id: user.id, medal: :gold, reason: :perfect_lesson_first_try}
      attrs_silver = %{user_id: user.id, medal: :silver, reason: :perfect_lesson_first_try}
      attrs_bronze = %{user_id: user.id, medal: :bronze, reason: :perfect_lesson_first_try}

      Enum.each(1..3, fn _idx -> Gamification.create_user_medal(attrs_gold) end)
      Enum.each(1..2, fn _idx -> Gamification.create_user_medal(attrs_silver) end)
      Gamification.create_user_medal(attrs_bronze)

      assert Gamification.count_user_medals(user.id, :gold) == 3
      assert Gamification.count_user_medals(user.id, :silver) == 2
      assert Gamification.count_user_medals(user.id, :bronze) == 1
    end
  end
end
