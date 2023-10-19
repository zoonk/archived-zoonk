defmodule Uneebee.GamificationTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Gamification

  alias Uneebee.Gamification
  alias Uneebee.Gamification.UserMedal
  alias Uneebee.Gamification.UserMission
  alias Uneebee.Gamification.UserTrophy

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

  describe "first_lesson_today?/1" do
    test "returns true if the user has completed only one lesson today" do
      user = user_fixture()
      generate_user_lesson(user.id, -1)
      generate_user_lesson(user.id, 0, number_of_lessons: 1)

      assert Gamification.first_lesson_today?(user.id)
    end

    test "returns false if the user has completed more than one lesson today" do
      user = user_fixture()
      generate_user_lesson(user.id, 0)

      refute Gamification.first_lesson_today?(user.id)
    end
  end

  describe "create_user_trophy/1" do
    test "creates a user trophy" do
      user = user_fixture()
      course = course_fixture()
      attrs = %{user_id: user.id, course_id: course.id, reason: :course_completed}

      assert {:ok, %UserTrophy{} = user_trophy} = Gamification.create_user_trophy(attrs)
      assert user_trophy.user_id == attrs.user_id
      assert user_trophy.course_id == attrs.course_id
      assert user_trophy.reason == attrs.reason
    end

    test "returns an error if the reason is missing" do
      user = user_fixture()
      course = course_fixture()
      attrs = %{user_id: user.id, course_id: course.id}

      assert {:error, %Ecto.Changeset{} = changeset} = Gamification.create_user_trophy(attrs)
      assert "can't be blank" in errors_on(changeset).reason
    end

    test "don't duplicate trophies with the same course, user and reason" do
      user = user_fixture()
      course = course_fixture()
      attrs = %{user_id: user.id, course_id: course.id, reason: :course_completed}
      user_trophy_fixture(%{course: course, user: user, reason: :course_completed})

      assert {:ok, %UserTrophy{} = _user_trophy} = Gamification.create_user_trophy(attrs)
      assert Gamification.count_user_trophies(user.id) == 1
    end
  end

  describe "count_user_trophies/1" do
    test "returns the count of trophies for a given user" do
      user = user_fixture()
      Enum.each(1..3, fn _idx -> user_trophy_fixture(%{user: user}) end)
      assert Gamification.count_user_trophies(user.id) == 3
    end
  end

  describe "maybe_award_trophy/1" do
    test "awards a trophy if the user has completed a course" do
      user = user_fixture()
      course = course_fixture()
      generate_user_lesson(user.id, 0, course: course)

      assert {:ok, %UserTrophy{} = _user_trophy} = Gamification.maybe_award_trophy(%{user: user, course: course})
      assert Gamification.count_user_trophies(user.id) == 1
    end

    test "doesn't award a trophy if the user hasn't completed a course" do
      user = user_fixture()
      course = course_fixture()

      assert {:ok, %UserTrophy{} = _user_trophy} = Gamification.maybe_award_trophy(%{user: user, course: course})
      assert Gamification.count_user_trophies(user.id) == 0
    end
  end

  describe "get_course_completed_trophy/1" do
    test "returns a trophy if the user has completed a course" do
      user = user_fixture()
      course = course_fixture()
      user_trophy_fixture(%{user: user, course: course, reason: :course_completed})

      assert Gamification.get_course_completed_trophy(user.id, course.id)
    end

    test "doesn't return a trophy if the user hasn't completed a course" do
      user = user_fixture()
      course = course_fixture()
      other_course = course_fixture()

      user_trophy_fixture(%{user: user, course: other_course, reason: :course_completed})

      assert Gamification.get_course_completed_trophy(user.id, course.id) == nil
    end
  end

  describe "change_user_mission/2" do
    test "returns an `%Ecto.Changeset{}` for tracking user mission changes" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :profile_name}

      assert %Ecto.Changeset{} = Gamification.change_user_mission(%UserMission{}, attrs)
    end

    test "returns an error if the reason is missing" do
      user = user_fixture()
      attrs = %{user_id: user.id}

      changeset = Gamification.change_user_mission(%UserMission{}, attrs)
      assert "can't be blank" in errors_on(changeset).reason
    end

    test "returns an error if the user_id is missing" do
      attrs = %{reason: :profile_name}

      changeset = Gamification.change_user_mission(%UserMission{}, attrs)
      assert "can't be blank" in errors_on(changeset).user_id
    end
  end

  describe "create_user_mission/1" do
    test "creates a user mission" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :profile_name}

      assert {:ok, %UserMission{} = user_mission} = Gamification.create_user_mission(attrs)
      assert user_mission.user_id == attrs.user_id
      assert user_mission.reason == attrs.reason
    end

    test "don't duplicate missions with the same user and reason" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :profile_name}
      mission = user_mission_fixture(%{user: user, reason: :profile_name})

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "earns a trophy when a user completes the profile_name mission" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :profile_name}

      assert Gamification.count_user_trophies(user.id) == 0
      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_trophies(user.id) == 1
    end

    test "doesn't award a trophy for a duplicated mission" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :profile_name}
      user_mission_fixture(%{user: user, reason: :profile_name})

      assert Gamification.count_user_trophies(user.id) == 1
      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_trophies(user.id) == 1
    end

    test "earns a trophy when a user completes their first lesson" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_1}

      assert Gamification.count_user_trophies(user.id) == 0
      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_trophies(user.id) == 1
    end

    test "earns a bronze medal when a user completes 5 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_5}

      assert Gamification.count_user_medals(user.id, :bronze) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :bronze) == 1
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "earns a bronze medal when a user completes 10 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_10}

      assert Gamification.count_user_medals(user.id, :bronze) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :bronze) == 1
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "earns a silver medal when a user completes 50 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_50}

      assert Gamification.count_user_medals(user.id, :silver) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :silver) == 1
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "earns a gold medal when a user completes 100 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_100}

      assert Gamification.count_user_medals(user.id, :gold) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :gold) == 1
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "earns a gold medal when a user completes 500 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_500}

      assert Gamification.count_user_medals(user.id, :gold) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :gold) == 1
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "earns a trophy when a user completes 1000 lessons" do
      user = user_fixture()
      attrs = %{user_id: user.id, reason: :lesson_1000}

      assert Gamification.count_user_medals(user.id, :gold) == 0
      assert Gamification.count_user_trophies(user.id) == 0

      assert {:ok, %UserMission{} = _mission} = Gamification.create_user_mission(attrs)
      assert Gamification.count_user_medals(user.id, :gold) == 0
      assert Gamification.count_user_trophies(user.id) == 1
    end
  end

  describe "delete_user_mission/1" do
    test "deletes a user mission" do
      user = user_fixture()
      mission = user_mission_fixture(%{user: user, reason: :profile_name})

      assert {:ok, %UserMission{} = _mission} = Gamification.delete_user_mission(mission.id)
      assert Gamification.completed_missions(user.id) == []
      assert Gamification.get_user_mission(:profile_name, user.id) == nil
    end

    test "deletes the trophy associated with this mission" do
      user = user_fixture()
      mission = user_mission_fixture(%{user: user, reason: :profile_name})

      assert Gamification.count_user_trophies(user.id) == 1
      assert {:ok, %UserMission{} = _mission} = Gamification.delete_user_mission(mission.id)
      assert Gamification.count_user_trophies(user.id) == 0
    end
  end

  describe "get_user_mission/2" do
    test "returns a mission if the user has completed it" do
      user = user_fixture()
      mission = user_mission_fixture(%{user: user, reason: :profile_name})

      assert Gamification.get_user_mission(:profile_name, user.id) == mission
    end

    test "returns nil if the user hasn't completed it" do
      user = user_fixture()
      user_mission_fixture(%{user: user, reason: :profile_name})

      assert Gamification.get_user_mission(:lesson_1, user.id) == nil
    end
  end

  describe "completed_missions/1" do
    test "returns a list of completed missions for a given user" do
      user = user_fixture()
      mission1 = user_mission_fixture(%{user: user, reason: :profile_name})
      mission2 = user_mission_fixture(%{user: user, reason: :lesson_1})

      assert Gamification.completed_missions(user.id) == [mission2, mission1]
    end
  end

  describe "complete_user_mission/2" do
    test "creates a mission when the first name exists" do
      user = user_fixture(%{first_name: "Albert", last_name: nil})
      assert {:ok, %UserMission{} = mission} = Gamification.complete_user_mission(user, :profile)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the last name exists" do
      user = user_fixture(%{first_name: nil, last_name: "Einstein"})
      assert {:ok, %UserMission{} = mission} = Gamification.complete_user_mission(user, :profile)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "deletes a mission when neither the first name nor the last exist" do
      user = user_fixture(%{first_name: nil, last_name: nil})
      user_mission_fixture(%{user: user, reason: :profile_name})

      assert {:ok, %UserMission{} = _mission} = Gamification.complete_user_mission(user, :profile)
      assert Gamification.completed_missions(user.id) == []
      assert Gamification.get_user_mission(:profile_name, user.id) == nil
    end
  end

  describe "complete_lesson_mission/2" do
    test "creates a mission when the user has completed their first lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 1)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their fifth lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 5)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their tenth lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 10)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their 50th lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 50)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their 100th lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 100)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their 500th lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 500)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed their 1000th lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_lesson_mission(user, 1000)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "doesn't create a mission when the user has completed a random number of lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = _mission} = Gamification.complete_lesson_mission(user, 42)
      assert Gamification.completed_missions(user.id) == []
    end
  end

  describe "complete_perfect_lesson_mission/2" do
    test "creates a mission when the user has completed their first perfect lesson" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_perfect_lesson_mission(user, 1)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed 10 perfect lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_perfect_lesson_mission(user, 10)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed 50 perfect lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_perfect_lesson_mission(user, 50)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed 100 perfect lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_perfect_lesson_mission(user, 100)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "creates a mission when the user has completed 500 perfect lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = mission} = Gamification.complete_perfect_lesson_mission(user, 500)
      assert Gamification.completed_missions(user.id) == [mission]
    end

    test "doesn't create a mission when the user has completed a random number of perfect lessons" do
      user = user_fixture()
      assert {:ok, %UserMission{} = _mission} = Gamification.complete_perfect_lesson_mission(user, 42)
      assert Gamification.completed_missions(user.id) == []
    end
  end
end
