defmodule Zoonk.ContentTest do
  @moduledoc false
  use Zoonk.DataCase, async: true

  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Content
  alias Zoonk.Content.Course
  alias Zoonk.Content.CourseData
  alias Zoonk.Content.CourseUser
  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.StepSuggestedCourse
  alias Zoonk.Content.UserLesson
  alias Zoonk.Content.UserSelection
  alias Zoonk.Organizations
  alias Zoonk.Repo

  describe "change_course/2" do
    test "returns a course changeset" do
      course = course_fixture()
      assert %Ecto.Changeset{} = Content.change_course(course, %{})
    end
  end

  describe "get_course!/1" do
    test "returns a course" do
      course = course_fixture()
      assert %Course{} = Content.get_course!(course.id)
    end

    test "raises if the course does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Content.get_course!(0) end
    end
  end

  describe "create_course/1" do
    test "creates a course" do
      attrs = valid_course_attributes()
      user = user_fixture()

      assert {:ok, %Course{} = course} = Content.create_course(attrs, user)
      assert course.description == attrs.description
      assert course.published? == attrs.published?
      assert course.name == attrs.name
      assert course.school_id == attrs.school_id
      assert course.slug == attrs.slug

      # Should automatically create a lesson
      assert Content.count_lessons(course.id) == 1
    end

    test "returns an error if the slug already exists on the same school" do
      course = course_fixture()
      user = user_fixture()
      attrs = valid_course_attributes(%{slug: course.slug, school_id: course.school_id})

      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_course(attrs, user)
      assert "has already been taken" in errors_on(changeset).slug
    end

    test "allow two schools to have courses with the same slug" do
      school1 = school_fixture()
      school2 = school_fixture()
      course1 = course_fixture(%{school_id: school1.id})
      user = user_fixture()
      attrs = valid_course_attributes(%{slug: course1.slug, school: school2})

      assert {:ok, %Course{} = course} = Content.create_course(attrs, user)
      assert course.slug == attrs.slug
    end

    test "returns an error if the slug has spaces" do
      attrs = valid_course_attributes(%{slug: "bad slug"})
      user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_course(attrs, user)
      assert "can only contain letters, numbers, dashes and underscores" in errors_on(changeset).slug
    end

    test "returns an error if the slug has special characters" do
      attrs = valid_course_attributes(%{slug: "bad-slug!"})
      user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_course(attrs, user)
      assert "can only contain letters, numbers, dashes and underscores" in errors_on(changeset).slug
    end
  end

  describe "update_course/2" do
    test "with valid data updates the course" do
      course = course_fixture()

      attrs = %{description: "new description", language: :pt, level: :advanced, public?: true, published?: false, slug: "new-slug"}

      assert {:ok, %Course{} = course} = Content.update_course(course, attrs)
      assert course.description == attrs.description
      assert course.language == attrs.language
      assert course.level == attrs.level
      assert course.public? == attrs.public?
      assert course.published? == attrs.published?
      assert course.slug == attrs.slug
    end

    test "with invalid data returns error changeset" do
      course = course_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_course(course, %{slug: ""})
    end

    test "update the name of a course" do
      course = course_fixture()
      assert {:ok, %Course{} = course} = Content.update_course(course, %{"name" => "New name"})
      assert course.name == "New name"
    end
  end

  describe "get_course_by_slug!/1" do
    test "returns a course" do
      course = course_fixture()
      assert %Course{} = Content.get_course_by_slug!(course.slug, course.school_id)
    end

    test "raises if the course does not exist" do
      school = school_fixture()
      assert_raise Ecto.NoResultsError, fn -> Content.get_course_by_slug!("bad-slug", school.id) end
    end
  end

  describe "list_courses_by_school/1" do
    test "returns all courses for a given school" do
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id, language: :pt, preload: :school})
      course2 = course_fixture(%{school_id: school.id, language: :en, preload: :school})
      course3 = course_fixture(%{school_id: school.id, published?: false, preload: :school})

      courses = Content.list_courses_by_school(school.id)

      assert courses == [course3, course2, course1]
    end
  end

  describe "list_public_courses_by_school/3" do
    test "returns all public courses for a given school" do
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id, published?: true, public?: true, preload: :school})
      course2 = course_fixture(%{school_id: school.id, published?: true, public?: true, preload: :school})

      course_fixture(%{school_id: school.id, published?: false, public?: true})
      course_fixture(%{school_id: school.id, published?: true, public?: false})
      course_fixture(%{school_id: school.id, published?: true, public?: true, language: :pt})

      Enum.each(1..3, fn _idx -> course_user_fixture(%{course: course1}) end)

      courses = Content.list_public_courses_by_school(school, :en)

      assert courses == [
               %CourseData{id: course1.id, data: course1, student_count: 3},
               %CourseData{id: course2.id, data: course2, student_count: 0}
             ]
    end

    test "limits how many courses are returned" do
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id, published?: true, public?: true, preload: :school})
      course2 = course_fixture(%{school_id: school.id, published?: true, public?: true, preload: :school})

      course_fixture(%{school_id: school.id, published?: true, public?: true, preload: :school})

      Enum.each(1..3, fn _idx -> course_user_fixture(%{course: course1}) end)

      courses = Content.list_public_courses_by_school(school, :en, limit: 2)

      assert courses == [
               %CourseData{id: course1.id, data: course1, student_count: 3},
               %CourseData{id: course2.id, data: course2, student_count: 0}
             ]
    end
  end

  describe "list_courses_by_user/3" do
    test "lists all courses a user has enrolled in" do
      user = user_fixture()
      school = school_fixture()
      enrolled1 = course_fixture(%{school_id: school.id, preload: :school})
      enrolled2 = course_fixture(%{school_id: school.id, preload: :school})
      teacher = course_fixture(%{school_id: school.id})
      course_fixture(%{school_id: school.id})

      course_user_fixture(%{user_id: user.id, course_id: enrolled1.id, role: :student})
      course_user_fixture(%{user_id: user.id, course_id: enrolled2.id, role: :student})
      course_user_fixture(%{user_id: user.id, course_id: teacher.id, role: :teacher})

      courses = Content.list_courses_by_user(school.id, user.id, :student)
      assert courses == [enrolled2, enrolled1]
    end

    test "list all courses a user is a teacher" do
      user = user_fixture()
      school = school_fixture()
      enrolled = course_fixture(%{school_id: school.id})
      teacher1 = course_fixture(%{school_id: school.id, preload: :school})
      teacher2 = course_fixture(%{school_id: school.id, preload: :school})
      course_fixture(%{school_id: school.id})

      course_user_fixture(%{user_id: user.id, course_id: enrolled.id, role: :student})
      course_user_fixture(%{user_id: user.id, course_id: teacher1.id, role: :teacher})
      course_user_fixture(%{user_id: user.id, course_id: teacher2.id, role: :teacher})

      courses = Content.list_courses_by_user(school.id, user.id, :teacher)
      assert courses == [teacher2, teacher1]
    end

    test "limit the number of records displayed" do
      user = user_fixture()
      school = school_fixture()
      enrolled1 = course_fixture(%{school_id: school.id, preload: :school})
      enrolled2 = course_fixture(%{school_id: school.id, preload: :school})
      teacher = course_fixture(%{school_id: school.id})
      course_fixture(%{school_id: school.id})

      course_user_fixture(%{user_id: user.id, course_id: enrolled1.id, role: :student})
      course_user_fixture(%{user_id: user.id, course_id: enrolled2.id, role: :student})
      course_user_fixture(%{user_id: user.id, course_id: teacher.id, role: :teacher})

      courses = Content.list_courses_by_user(school.id, user.id, :student, limit: 1)
      assert courses == [enrolled2]
    end

    test "doesn't return courses from another school" do
      user = user_fixture()
      school = school_fixture()
      other_school = school_fixture()
      enrolled = course_fixture(%{school_id: school.id, preload: :school})
      course_fixture(%{school_id: other_school.id})

      course_user_fixture(%{user_id: user.id, course_id: enrolled.id, role: :student})

      courses = Content.list_courses_by_user(school.id, user.id, :student)
      assert courses == [enrolled]
    end
  end

  describe "delete_course/1" do
    test "removes a course from the database" do
      user = user_fixture()
      course = course_fixture(%{user: user})

      assert {:ok, %Course{}} = Content.delete_course(course)
      assert_raise Ecto.NoResultsError, fn -> Content.get_course_by_slug!(course.slug, course.school_id) end
    end

    test "removes all course users" do
      user = user_fixture()
      course = course_fixture()
      course_user_fixture(%{course: course, user: user})

      assert length(Content.list_course_users(course.id)) == 1
      Content.delete_course(course)
      assert Content.list_course_users(course.id) == []
    end

    test "removes all lessons" do
      course = course_fixture()
      lesson_fixture(%{course: course})

      assert length(Content.list_lessons(course.id)) == 1
      Content.delete_course(course)
      assert Content.list_lessons(course.id) == []
    end
  end

  describe "create_course_user/3" do
    test "adds a student" do
      school = school_fixture()
      course = course_fixture(%{school_id: school.id})
      user = user_fixture()
      manager = user_fixture()

      assert {:ok, %CourseUser{} = course_user} = Content.create_course_user(course, user, %{role: :student, approved?: true, approved_by_id: manager.id})

      assert course_user.course_id == course.id
      assert course_user.user_id == user.id
      assert course_user.role == :student

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :student
      assert school_user.approved? == true
      assert school_user.approved_by_id == manager.id
    end

    test "adds a teacher" do
      school = school_fixture()
      course = course_fixture(%{school_id: school.id})
      user = user_fixture()
      manager = user_fixture()

      assert {:ok, %CourseUser{} = course_user} = Content.create_course_user(course, user, %{role: :teacher, approved?: true, approved_by_id: manager.id})

      assert course_user.course_id == course.id
      assert course_user.user_id == user.id
      assert course_user.role == :teacher

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :teacher
      assert school_user.approved? == true
      assert school_user.approved_by_id == manager.id
    end

    test "returns an error if the role is invalid" do
      course = course_fixture()
      user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_course_user(course, user, %{role: :bad})
      assert "is invalid" in errors_on(changeset).role
    end

    test "when adding a user as course teacher, make it a school teacher too" do
      school = school_fixture()
      course = course_fixture(%{school_id: school.id})
      user = user_fixture()
      manager = user_fixture()
      school_user_fixture(%{school_id: school.id, user_id: user.id, role: :student})

      assert {:ok, %CourseUser{} = _cu} = Content.create_course_user(course, user, %{role: :teacher, approved?: true, approved_by_id: manager.id})

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :teacher
      assert school_user.approved? == true
      assert school_user.approved_by_id == manager.id
    end
  end

  describe "get_course_user_by_id/2" do
    test "returns an existing course user" do
      course_user = course_user_fixture()
      assert %CourseUser{} = Content.get_course_user_by_id(course_user.course_id, course_user.user_id)
    end

    test "returns nil if the course user does not exist" do
      assert Content.get_course_user_by_id(1, 1) == nil
    end
  end

  describe "search_course_users/2" do
    test "search a course user" do
      course = course_fixture()
      user = user_fixture(%{first_name: "Albert", last_name: "Einstein", username: "user-#{System.unique_integer()}-einstein"})
      course_user = course_user_fixture(%{course: course, user: user, preload: :user})

      assert Content.search_course_users(course.id, user.username) == [course_user]
      assert Content.search_course_users(course.id, "Einstein") == [course_user]
      assert Content.search_course_users(course.id, "eins") == [course_user]
      assert Content.search_course_users(course.id, user.email) == [course_user]
      assert Content.search_course_users(course.id, user.first_name) == [course_user]
      assert Content.search_course_users(course.id, user.last_name) == [course_user]
      assert Content.search_course_users(course.id, "alb") == [course_user]
      assert Content.search_course_users(course.id, "albert einstein") == [course_user]
      assert Content.search_course_users(course.id, "invalid") == []
    end
  end

  describe "list_course_users/1" do
    test "list course users" do
      teacher = user_fixture()
      course = course_fixture(%{user: teacher})

      course_user1 = course_user_fixture(%{role: :student, course: course, preload: :user})
      course_user2 = course_user_fixture(%{role: :teacher, course: course, preload: :user})
      course_user3 = course_user_fixture(%{role: :student, course: course, preload: :user})

      assert Content.list_course_users(course.id) == [course_user3, course_user2, course_user1]
    end
  end

  describe "list_course_users_by_role/2" do
    test "limits and offsets course users" do
      course = course_fixture()

      course_user_fixture(%{role: :student, course: course})
      course_user1 = course_user_fixture(%{role: :student, course: course, preload: :user})
      course_user2 = course_user_fixture(%{role: :student, course: course, preload: :user})
      course_user3 = course_user_fixture(%{role: :student, course: course, preload: :user})
      course_user_fixture(%{role: :student, course: course})

      assert Content.list_course_users(course.id, limit: 3, offset: 1) == [course_user3, course_user2, course_user1]
    end
  end

  describe "update_course_user/2" do
    test "updates a course user" do
      course_user = course_user_fixture()

      assert {:ok, %CourseUser{} = updated} = Content.update_course_user(course_user, %{role: :teacher})
      assert updated.role == :teacher
    end

    test "returns an error if the role is invalid" do
      course_user = course_user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_course_user(course_user, %{role: :manager})
      assert "is invalid" in errors_on(changeset).role
    end
  end

  describe "approve_course_user/2" do
    test "approves a course user" do
      teacher = user_fixture()
      course_user = course_user_fixture(%{role: :student, approved?: false, approved_by_id: nil, approved_at: nil})

      assert {:ok, %CourseUser{} = updated} = Content.approve_course_user(course_user.id, teacher.id)
      assert updated.approved? == true
      assert updated.approved_by_id == teacher.id
    end
  end

  describe "delete_course_user/1" do
    test "removes a course user from the database" do
      course_user = course_user_fixture()
      assert {:ok, %CourseUser{}} = Content.delete_course_user(course_user.id)
      assert Content.get_course_user_by_id(course_user.course_id, course_user.user_id) == nil
    end
  end

  describe "get_course_users_count/1" do
    test "returns the number of users in a course" do
      course = course_fixture()
      Enum.each(1..3, fn _idx -> course_user_fixture(%{role: :student, course: course}) end)
      course_user_fixture(%{role: :teacher, course: course})

      assert Content.get_course_users_count(course.id) == 4
    end
  end

  describe "get_course_users_count/2" do
    test "returns the number of students in a course" do
      course = course_fixture()
      Enum.each(1..3, fn _idx -> course_user_fixture(%{role: :student, course: course}) end)
      course_user_fixture(%{role: :teacher, course: course})

      assert Content.get_course_users_count(course, :student) == 3
    end

    test "returns the number of teachers in a course" do
      course = course_fixture()
      Enum.each(1..3, fn _idx -> course_user_fixture(%{role: :teacher, course: course}) end)
      course_user_fixture(%{role: :student, course: course})

      assert Content.get_course_users_count(course, :teacher) == 3
    end
  end

  describe "change_lesson/2" do
    test "returns a lesson changeset" do
      lesson = lesson_fixture()
      assert %Ecto.Changeset{} = Content.change_lesson(lesson, %{})
    end
  end

  describe "create_lesson/2" do
    test "creates a lesson" do
      attrs = valid_lesson_attributes()
      assert {:ok, %Lesson{} = lesson} = Content.create_lesson(attrs)
      assert lesson.name == attrs.name
      assert lesson.course_id == attrs.course_id

      # Should automatically create a lesson step
      assert Content.count_lesson_steps(lesson.id) == 1
    end

    test "returns an error changeset" do
      attrs = valid_lesson_attributes(%{name: ""})
      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_lesson(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "update_lesson/2" do
    test "updates a lesson" do
      lesson = lesson_fixture()
      attrs = %{name: "New name"}
      assert {:ok, %Lesson{} = updated} = Content.update_lesson(lesson, attrs)
      assert updated.name == attrs.name
    end

    test "returns an error changeset" do
      lesson = lesson_fixture()
      attrs = %{name: ""}
      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_lesson(lesson, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "delete_lesson/1" do
    test "deletes a lesson" do
      lesson = lesson_fixture()
      lesson_step_fixture(%{lesson: lesson, order: 1})
      lesson_fixture(%{course_id: lesson.course_id})

      assert Content.get_lesson_step_by_order(lesson.id, 1)
      assert {:ok, %Lesson{}} = Content.delete_lesson(lesson)
      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(lesson.id) end
      refute Content.get_lesson_step_by_order(lesson.id, 1)
    end

    test "deletes all user lessons" do
      lesson = lesson_fixture()
      lesson_fixture(%{course_id: lesson.course_id})
      user = user_fixture()
      Content.add_user_lesson(%{attempts: 1, correct: 1, total: 1, user_id: user.id, lesson_id: lesson.id})

      assert Content.get_user_lesson(user.id, lesson.id)
      Content.delete_lesson(lesson)
      refute Content.get_user_lesson(user.id, lesson.id)
    end

    test "deletes all user selections" do
      lesson = lesson_fixture()
      lesson_fixture(%{course_id: lesson.course_id})
      user = user_fixture()
      lesson_step = lesson_step_fixture(%{lesson: lesson})
      step_option = step_option_fixture(%{lesson_step: lesson_step})
      Content.add_user_selection(%{duration: 5, correct: 1, total: 1, user_id: user.id, option_id: step_option.id, lesson_id: lesson.id, step_id: lesson_step.id})

      assert length(Content.list_user_selections_by_lesson(user.id, lesson.id, 1)) == 1
      Content.delete_lesson(lesson)
      assert Content.list_user_selections_by_lesson(user.id, lesson.id, 1) == []
    end

    test "updates the order field of the remaining lessons" do
      course = course_fixture()
      lesson1 = lesson_fixture(%{course: course, order: 1, name: "Lesson 1"})
      lesson2 = lesson_fixture(%{course: course, order: 2, name: "Lesson 2"})
      lesson3 = lesson_fixture(%{course: course, order: 3, name: "Lesson 3"})
      lesson4 = lesson_fixture(%{course: course, order: 4, name: "Lesson 4"})

      Content.delete_lesson(lesson2)

      assert Content.get_lesson!(lesson1.id).order == 1
      assert Content.get_lesson!(lesson3.id).order == 2
      assert Content.get_lesson!(lesson4.id).order == 3
    end

    test "cannot delete the only lesson" do
      lesson = lesson_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.delete_lesson(lesson)
      assert "cannot delete the only lesson" in errors_on(changeset).base
      assert Content.get_lesson!(lesson.id) == lesson
    end
  end

  describe "list_lessons/1" do
    test "returns a list of lessons" do
      course = course_fixture()
      lesson1 = lesson_fixture(%{course: course, order: 2})
      lesson2 = lesson_fixture(%{course: course, order: 3})
      lesson3 = lesson_fixture(%{course: course, order: 1})

      assert Content.list_lessons(course.id) == [lesson3, lesson1, lesson2]
    end
  end

  describe "list_lessons_with_stats/1" do
    test "returns a list of lessons with stats" do
      course = course_fixture()
      lessons = Enum.map(1..3, fn _idx -> lesson_fixture(%{course: course}) end)
      users = Enum.map(1..3, fn _idx -> user_fixture() end)

      Enum.each(lessons, fn lesson ->
        Enum.each(users, fn user ->
          {:ok, _ul} = Content.add_user_lesson(%{duration: 5, user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 3, total: 5})
        end)
      end)

      lesson_list = Content.list_lessons_with_stats(course.id)
      assert length(lesson_list) == 3

      {lesson, stats} = Enum.at(lesson_list, 0)
      assert stats.users == 3
      assert lesson.user_lessons == []
    end
  end

  describe "count_lessons/1" do
    test "returns the number of lessons in a course" do
      course = course_fixture()
      lesson_fixture(%{course: course})
      lesson_fixture(%{course: course})
      lesson_fixture(%{course: course})

      assert Content.count_lessons(course.id) == 3
    end
  end

  describe "get_first_lesson/1" do
    test "returns the first lesson" do
      course = course_fixture()
      lesson_fixture(%{course: course, order: 2})
      lesson_fixture(%{course: course, order: 3})
      lesson3 = lesson_fixture(%{course: course, order: 1})

      assert Content.get_first_lesson(course) == lesson3
    end

    test "returns nil if there are no lessons" do
      course = course_fixture()
      assert Content.get_first_lesson(course) == nil
    end
  end

  describe "list_published_lessons/2" do
    test "returns a list of published lessons" do
      course = course_fixture()
      lesson1 = lesson_fixture(%{course_id: course.id, order: 3, published?: true})
      lesson2 = lesson_fixture(%{course_id: course.id, order: 2, published?: true})
      lesson_fixture(%{course_id: course.id, order: 1, published?: false})

      assert Content.list_published_lessons(course, nil) == [lesson2, lesson1]
    end

    test "preloads lessons for a given user" do
      course = course_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      lesson = lesson_fixture(%{course_id: course.id, order: 1, published?: true})

      {:ok, _ul} = Content.add_user_lesson(%{user_id: user1.id, lesson_id: lesson.id, attempts: 1, correct: 3, total: 5})
      {:ok, _ul} = Content.add_user_lesson(%{user_id: user2.id, lesson_id: lesson.id, attempts: 1, correct: 3, total: 5})

      published_lessons = Content.list_published_lessons(course, user1)
      first_lesson = Enum.at(published_lessons, 0)
      user_lesson = Enum.at(first_lesson.user_lessons, 0)

      assert user_lesson.user_id == user1.id
      assert user_lesson.lesson_id == lesson.id
      assert user_lesson.attempts == 1
      assert user_lesson.correct == 3
      assert user_lesson.total == 5

      assert length(first_lesson.user_lessons) == 1
    end
  end

  describe "list_published_lessons/3" do
    test "preloads wrong user selections" do
      user = user_fixture()
      course = course_fixture()

      lesson1 = lesson_fixture(%{course_id: course.id, order: 1, published?: true})
      lesson2 = lesson_fixture(%{course_id: course.id, order: 2, published?: true})

      lesson_step1 = lesson_step_fixture(%{lesson_id: lesson1.id, order: 1})
      lesson_step2 = lesson_step_fixture(%{lesson_id: lesson2.id, order: 1})
      lesson_step3 = lesson_step_fixture(%{lesson_id: lesson2.id, order: 2, kind: :open_ended})

      Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 1, total: 1, lesson_id: lesson1.id, step_id: lesson_step1.id})
      Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 0, total: 1, lesson_id: lesson1.id, step_id: lesson_step1.id})
      Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 1, total: 1, lesson_id: lesson2.id, step_id: lesson_step2.id})
      Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 1, total: 1, answer: ["test"], lesson_id: lesson2.id, step_id: lesson_step3.id})

      Content.add_user_lesson(%{duration: 5, user_id: user.id, lesson_id: lesson1.id, attempts: 1, correct: 3, total: 5})
      Content.add_user_lesson(%{duration: 5, user_id: user.id, lesson_id: lesson2.id, attempts: 1, correct: 3, total: 5})

      lessons = Content.list_published_lessons(course, user, selections?: true)
      first_lesson = Enum.at(lessons, 0)
      second_lesson = Enum.at(lessons, 1)

      assert length(first_lesson.user_selections) == 1
      assert Enum.at(second_lesson.user_selections, 0).answer == ["test"]

      assert length(first_lesson.user_lessons) == 1
      assert length(second_lesson.user_lessons) == 1
    end
  end

  describe "get_lesson!/1" do
    test "returns a lesson" do
      lesson = lesson_fixture()
      assert Content.get_lesson!(lesson.id) == lesson
    end

    test "raises an error if the lesson does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(-1) end
    end
  end

  describe "get_lesson!/3" do
    test "returns a lesson" do
      course = course_fixture()
      lesson = lesson_fixture(%{course: course})
      assert Content.get_lesson!(course.slug, lesson.id) == lesson
    end

    test "raises an error if the lesson does not exist" do
      course = course_fixture()
      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(course.slug, -1) end
    end

    test "raises an error if trying to access a lesson from another course" do
      course1 = course_fixture()
      course2 = course_fixture()

      lesson1 = lesson_fixture(%{course: course1})
      lesson2 = lesson_fixture(%{course: course2})

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(course1.slug, lesson2.id) end
      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(course2.slug, lesson1.id) end
    end

    test "raises an error if trying to access an unpublished lesson when public? option is passed" do
      course = course_fixture()
      lesson = lesson_fixture(%{course: course, published?: false})

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(course.slug, lesson.id, public?: true) end
    end

    test "returns the lesson when unpublished and public? option is not passed" do
      course = course_fixture()
      lesson = lesson_fixture(%{course: course, published?: false})

      assert Content.get_lesson!(course.slug, lesson.id) == lesson
    end
  end

  describe "update_lesson_order/3" do
    test "move a lesson up" do
      course = course_fixture()

      Enum.each(1..6, fn order -> lesson_fixture(%{course_id: course.id, name: "Lesson #{order}", order: order}) end)

      {:ok, lessons} = Content.update_lesson_order(course.id, 4, 1)

      assert Enum.at(lessons, 0).name == "Lesson 1"
      assert Enum.at(lessons, 1).name == "Lesson 5"
      assert Enum.at(lessons, 2).name == "Lesson 2"
      assert Enum.at(lessons, 3).name == "Lesson 3"
      assert Enum.at(lessons, 4).name == "Lesson 4"
      assert Enum.at(lessons, 5).name == "Lesson 6"
    end

    test "move a lesson down" do
      course = course_fixture()

      Enum.each(1..6, fn order -> lesson_fixture(%{course_id: course.id, name: "Lesson #{order}", order: order}) end)

      {:ok, lessons} = Content.update_lesson_order(course.id, 1, 4)

      assert Enum.at(lessons, 0).name == "Lesson 1"
      assert Enum.at(lessons, 1).name == "Lesson 3"
      assert Enum.at(lessons, 2).name == "Lesson 4"
      assert Enum.at(lessons, 3).name == "Lesson 5"
      assert Enum.at(lessons, 4).name == "Lesson 2"
      assert Enum.at(lessons, 5).name == "Lesson 6"
    end
  end

  describe "change_lesson_step/2" do
    test "returns a lesson step changeset" do
      lesson_step = lesson_step_fixture()
      assert %Ecto.Changeset{} = Content.change_lesson_step(lesson_step, %{})
    end
  end

  describe "create_lesson_step/2" do
    test "creates a lesson step" do
      attrs = valid_lesson_step_attributes()
      assert {:ok, %LessonStep{} = lesson_step} = Content.create_lesson_step(attrs)
      assert lesson_step.content == attrs.content
      assert lesson_step.lesson_id == attrs.lesson_id
    end

    test "allow fill steps to have long segments" do
      text = String.duplicate("a", 1000)
      attrs = valid_lesson_step_attributes(%{kind: :fill, content: nil, segments: [text]})
      assert {:ok, %LessonStep{} = lesson_step} = Content.create_lesson_step(attrs)
      assert lesson_step.segments == [text]
      assert lesson_step.content == nil
    end

    test "returns an error changeset" do
      attrs = valid_lesson_step_attributes(%{content: ""})
      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_lesson_step(attrs)
      assert "can't be blank" in errors_on(changeset).content
    end
  end

  describe "update_lesson_step/2" do
    test "updates a lesson step" do
      lesson_step = lesson_step_fixture()
      attrs = %{content: "New content"}
      assert {:ok, %LessonStep{} = updated} = Content.update_lesson_step(lesson_step, attrs)
      assert updated.content == attrs.content
    end

    test "returns an error changeset" do
      lesson_step = lesson_step_fixture()
      attrs = %{content: ""}
      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_lesson_step(lesson_step, attrs)
      assert "can't be blank" in errors_on(changeset).content
    end
  end

  describe "delete_lesson_step/1" do
    test "deletes a lesson step" do
      lesson = lesson_fixture()
      lesson_step_fixture(%{lesson: lesson})
      lesson_step = lesson_step_fixture(%{lesson: lesson})
      assert {:ok, %LessonStep{}} = Content.delete_lesson_step(lesson_step.id)
      assert_raise Ecto.NoResultsError, fn -> Zoonk.Repo.get!(LessonStep, lesson_step.id) end
    end

    test "cannot delete the only lesson step" do
      lesson = lesson_fixture()
      lesson_step = lesson_step_fixture(%{lesson: lesson})

      assert {:error, %Ecto.Changeset{} = changeset} = Content.delete_lesson_step(lesson_step.id)
      assert "cannot delete the only step" in errors_on(changeset).base
      assert Content.get_lesson_step_by_order(lesson.id, lesson_step.order) == lesson_step
    end

    test "update the order field when deleting a step" do
      lesson = lesson_fixture()
      lesson_step1 = lesson_step_fixture(%{lesson: lesson, order: 1, content: "Step 1"})
      lesson_step2 = lesson_step_fixture(%{lesson: lesson, order: 2, content: "Step 2"})
      lesson_step3 = lesson_step_fixture(%{lesson: lesson, order: 3, content: "Step 3"})
      lesson_step4 = lesson_step_fixture(%{lesson: lesson, order: 4, content: "Step 4"})
      lesson_step5 = lesson_step_fixture(%{lesson: lesson, order: 5, content: "Step 5"})

      assert {:ok, %LessonStep{}} = Content.delete_lesson_step(lesson_step3.id)
      assert Content.get_lesson_step_by_order(lesson.id, 1).id == lesson_step1.id
      assert Content.get_lesson_step_by_order(lesson.id, 2).id == lesson_step2.id
      assert Content.get_lesson_step_by_order(lesson.id, 3).id == lesson_step4.id
      assert Content.get_lesson_step_by_order(lesson.id, 4).id == lesson_step5.id
    end
  end

  describe "list_lesson_steps/1" do
    test "returns a list of lesson steps" do
      lesson = lesson_fixture()
      lesson_step1 = lesson_step_fixture(%{lesson: lesson, order: 2})
      lesson_step2 = lesson_step_fixture(%{lesson: lesson, order: 3})
      lesson_step3 = lesson_step_fixture(%{lesson: lesson, order: 1})

      assert Content.list_lesson_steps(lesson) == [lesson_step3, lesson_step1, lesson_step2]
    end
  end

  describe "get_next_step/2" do
    test "returns the next lesson step" do
      lesson = lesson_fixture()
      lesson_step_fixture(%{lesson: lesson, order: 1})
      lesson_step2 = lesson_step_fixture(%{lesson: lesson, order: 2, preload: [:options, suggested_courses: :course]})
      lesson_step3 = lesson_step_fixture(%{lesson: lesson, order: 3, preload: [:options, suggested_courses: :course]})

      assert Content.get_next_step(lesson, 1) == lesson_step2
      assert Content.get_next_step(lesson, 2) == lesson_step3
      assert Content.get_next_step(lesson, 3) == nil
    end
  end

  describe "get_lesson_step_by_order/2" do
    test "returns a lesson step" do
      lesson = lesson_fixture()
      lesson_step = lesson_step_fixture(%{lesson: lesson, order: 1})
      assert Content.get_lesson_step_by_order(lesson.id, lesson_step.order) == lesson_step
    end

    test "returns nil if the lesson step does not exist" do
      lesson = lesson_fixture()
      assert Content.get_lesson_step_by_order(lesson.id, 1) == nil
    end
  end

  describe "count_lesson_steps/1" do
    test "returns the number of lesson steps" do
      lesson = lesson_fixture()
      Enum.each(1..3, fn order -> lesson_step_fixture(%{lesson_id: lesson.id, order: order}) end)

      assert Content.count_lesson_steps(lesson.id) == 3
    end
  end

  describe "count_selections_by_lesson_step/1" do
    test "returns the number of times each option was selected" do
      user = user_fixture()
      lesson = lesson_fixture()
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id})
      step_option1 = step_option_fixture(%{lesson_step_id: lesson_step.id})
      step_option2 = step_option_fixture(%{lesson_step_id: lesson_step.id})
      step_option3 = step_option_fixture(%{lesson_step_id: lesson_step.id})

      Enum.each(1..3, fn _idx ->
        Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 1, total: 1, lesson_id: lesson.id, option_id: step_option1.id, step_id: lesson_step.id})
      end)

      Enum.each(1..2, fn _idx ->
        Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 0, total: 1, lesson_id: lesson.id, option_id: step_option2.id, step_id: lesson_step.id})
      end)

      Enum.each(1..1, fn _idx ->
        Content.add_user_selection(%{duration: 5, user_id: user.id, correct: 1, total: 1, lesson_id: lesson.id, option_id: step_option3.id, step_id: lesson_step.id})
      end)

      selections = Content.count_selections_by_lesson_step(lesson_step.id)
      option1 = Enum.find(selections, fn selection -> selection.option_id == step_option1.id end)
      option2 = Enum.find(selections, fn selection -> selection.option_id == step_option2.id end)
      option3 = Enum.find(selections, fn selection -> selection.option_id == step_option3.id end)

      assert option1.selections == 3
      assert option2.selections == 2
      assert option3.selections == 1
    end
  end

  describe "update_lesson_step_order/3" do
    test "move a lesson step up" do
      lesson = lesson_fixture()

      Enum.each(1..6, fn order -> lesson_step_fixture(%{lesson_id: lesson.id, content: "Lesson step #{order}", order: order}) end)

      {:ok, lesson_steps} = Content.update_lesson_step_order(lesson, 4, 1)

      assert Enum.at(lesson_steps, 0).content == "Lesson step 1"
      assert Enum.at(lesson_steps, 1).content == "Lesson step 5"
      assert Enum.at(lesson_steps, 2).content == "Lesson step 2"
      assert Enum.at(lesson_steps, 3).content == "Lesson step 3"
      assert Enum.at(lesson_steps, 4).content == "Lesson step 4"
      assert Enum.at(lesson_steps, 5).content == "Lesson step 6"
    end

    test "move a lesson step down" do
      lesson = lesson_fixture()

      Enum.each(1..6, fn order -> lesson_step_fixture(%{lesson_id: lesson.id, content: "Lesson step #{order}", order: order}) end)

      {:ok, lesson_steps} = Content.update_lesson_step_order(lesson, 1, 4)

      assert Enum.at(lesson_steps, 0).content == "Lesson step 1"
      assert Enum.at(lesson_steps, 1).content == "Lesson step 3"
      assert Enum.at(lesson_steps, 2).content == "Lesson step 4"
      assert Enum.at(lesson_steps, 3).content == "Lesson step 5"
      assert Enum.at(lesson_steps, 4).content == "Lesson step 2"
      assert Enum.at(lesson_steps, 5).content == "Lesson step 6"
    end
  end

  describe "change_step_option/2" do
    test "returns a step option changeset" do
      step_option = step_option_fixture()
      assert %Ecto.Changeset{} = Content.change_step_option(step_option, %{})
    end
  end

  describe "create_step_option/2" do
    test "creates a step option" do
      attrs = valid_step_option_attributes()
      assert {:ok, %StepOption{} = step_option} = Content.create_step_option(attrs)
      assert step_option.title == attrs.title
      assert step_option.lesson_step_id == attrs.lesson_step_id
    end

    test "returns an error changeset" do
      attrs = valid_step_option_attributes(%{title: ""})
      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_step_option(attrs)
      assert "can't be blank" in errors_on(changeset).title
    end

    test "creates an option for fill steps" do
      attrs = %{kind: :fill, segment: 1, title: "Option 1", lesson_step_id: lesson_step_fixture().id}
      assert {:ok, %StepOption{} = step_option} = Content.create_step_option(attrs)
      assert step_option.segment == attrs.segment
    end
  end

  describe "delete_step_option/1" do
    test "deletes a step option" do
      step_option = step_option_fixture()
      assert {:ok, %StepOption{}} = Content.delete_step_option(step_option.id)
      assert_raise Ecto.NoResultsError, fn -> Zoonk.Repo.get!(StepOption, step_option.id) end
    end
  end

  describe "update_step_option/2" do
    test "updates a step option" do
      step_option = step_option_fixture()
      attrs = %{title: "New title"}
      assert {:ok, %StepOption{} = step_option} = Content.update_step_option(step_option, attrs)
      assert step_option.title == attrs.title
    end

    test "returns an error changeset" do
      step_option = step_option_fixture()
      attrs = %{title: ""}

      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_step_option(step_option, attrs)
      assert "can't be blank" in errors_on(changeset).title
    end

    test "doesn't allow feedback to go above the limit" do
      step_option = step_option_fixture()
      max_length = CourseUtils.max_length(:option_feedback)
      attrs = %{feedback: String.duplicate("a", max_length + 1)}

      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_step_option(step_option, attrs)
      assert "should be at most #{max_length} character(s)" in errors_on(changeset).feedback
    end

    test "doesn't allow title to go above the limit" do
      step_option = step_option_fixture()
      max_length = CourseUtils.max_length(:option_title)
      attrs = %{title: String.duplicate("a", max_length + 1)}

      assert {:error, %Ecto.Changeset{} = changeset} = Content.update_step_option(step_option, attrs)
      assert "should be at most #{max_length} character(s)" in errors_on(changeset).title
    end
  end

  describe "get_step_option!/1" do
    test "returns a step option" do
      step_option = step_option_fixture()
      assert Content.get_step_option!(step_option.id) == step_option
    end

    test "raises an error" do
      assert_raise Ecto.NoResultsError, fn -> Content.get_step_option!(0) end
    end
  end

  describe "add_user_selection/1" do
    test "adds a user selection" do
      user = user_fixture()
      option = step_option_fixture(%{preload: :lesson_step})
      attrs = %{duration: 5, correct: 1, total: 1, user_id: user.id, option_id: option.id, lesson_id: option.lesson_step.lesson_id, step_id: option.lesson_step_id}
      assert {:ok, %UserSelection{} = user_selection} = Content.add_user_selection(attrs)

      assert user_selection.user_id == user.id
      assert user_selection.option_id == option.id
    end

    test "number of correct answers cannot be larger than total" do
      user = user_fixture()
      option = step_option_fixture(%{preload: :lesson_step})
      attrs = %{duration: 5, correct: 2, total: 1, user_id: user.id, option_id: option.id, lesson_id: option.lesson_step.lesson_id, step_id: option.lesson_step_id}
      assert {:error, %Ecto.Changeset{}} = Content.add_user_selection(attrs)
    end
  end

  describe "list_user_selections_by_lesson/3" do
    test "returns a list of user selections" do
      user = user_fixture()
      lesson1 = lesson_fixture()
      lesson_steps1 = Enum.map(1..3, fn idx -> lesson_step_fixture(%{lesson_id: lesson1.id, order: idx}) end)
      options1 = Enum.map(0..2, fn idx -> step_option_fixture(%{lesson_step_id: Enum.at(lesson_steps1, idx).id}) end)

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options1, 0).id,
        lesson_id: lesson1.id,
        step_id: Enum.at(lesson_steps1, 0).id
      })

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options1, 1).id,
        lesson_id: lesson1.id,
        step_id: Enum.at(lesson_steps1, 1).id
      })

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options1, 2).id,
        lesson_id: lesson1.id,
        step_id: Enum.at(lesson_steps1, 2).id
      })

      {:ok, us1} =
        Content.add_user_selection(%{
          duration: 5,
          correct: 1,
          total: 1,
          user_id: user.id,
          option_id: Enum.at(options1, 0).id,
          lesson_id: lesson1.id,
          step_id: Enum.at(lesson_steps1, 0).id
        })

      {:ok, us2} =
        Content.add_user_selection(%{
          duration: 5,
          correct: 1,
          total: 1,
          user_id: user.id,
          option_id: Enum.at(options1, 1).id,
          lesson_id: lesson1.id,
          step_id: Enum.at(lesson_steps1, 1).id
        })

      {:ok, us3} =
        Content.add_user_selection(%{
          duration: 5,
          correct: 1,
          total: 1,
          user_id: user.id,
          option_id: Enum.at(options1, 2).id,
          lesson_id: lesson1.id,
          step_id: Enum.at(lesson_steps1, 2).id
        })

      lesson2 = lesson_fixture()
      lesson_steps2 = Enum.map(1..3, fn idx -> lesson_step_fixture(%{lesson_id: lesson2.id, order: idx}) end)
      options2 = Enum.map(0..2, fn idx -> step_option_fixture(%{lesson_step_id: Enum.at(lesson_steps2, idx).id}) end)

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options2, 0).id,
        lesson_id: lesson2.id,
        step_id: Enum.at(lesson_steps2, 0).id
      })

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options2, 1).id,
        lesson_id: lesson2.id,
        step_id: Enum.at(lesson_steps2, 1).id
      })

      Content.add_user_selection(%{
        duration: 5,
        correct: 1,
        total: 1,
        user_id: user.id,
        option_id: Enum.at(options2, 2).id,
        lesson_id: lesson2.id,
        step_id: Enum.at(lesson_steps2, 2).id
      })

      user_selection1 = Repo.get(UserSelection, us1.id)
      user_selection2 = Repo.get(UserSelection, us2.id)
      user_selection3 = Repo.get(UserSelection, us3.id)

      assert Content.list_user_selections_by_lesson(user.id, lesson1.id, 3) == [user_selection3, user_selection2, user_selection1]
    end
  end

  describe "change_user_lesson/2" do
    test "returns a user lesson changeset" do
      assert %Ecto.Changeset{} = Content.change_user_lesson(%UserLesson{}, %{})
    end
  end

  describe "add_user_lesson/1" do
    test "adds a user lesson" do
      user = user_fixture()
      lesson = lesson_fixture()
      attrs = %{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 4, total: 10}

      assert {:ok, %UserLesson{} = user_lesson} = Content.add_user_lesson(attrs)
      assert user_lesson.user_id == user.id
      assert user_lesson.lesson_id == lesson.id
    end

    test "updates the user lesson if it already exists" do
      user = user_fixture()
      lesson = lesson_fixture()
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 4, total: 10})

      attrs = %{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 5, total: 10}

      assert {:ok, %UserLesson{} = user_lesson} = Content.add_user_lesson(attrs)
      assert user_lesson.user_id == user.id
      assert user_lesson.lesson_id == lesson.id
      assert user_lesson.attempts == 2
      assert user_lesson.correct == 5
      assert user_lesson.total == 10
    end
  end

  describe "get_user_lesson/2" do
    test "returns a user lesson" do
      user = user_fixture()
      lesson = lesson_fixture()

      {:ok, user_lesson} = Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 4, total: 10})

      assert Content.get_user_lesson(user.id, lesson.id) == user_lesson
    end

    test "returns nil if the user lesson does not exist" do
      assert Content.get_user_lesson(1, 1) == nil
    end
  end

  describe "mark_lesson_as_completed/3" do
    test "marks a lesson as completed" do
      user = user_fixture()
      lesson1 = lesson_fixture()
      lesson_steps1 = Enum.map(1..3, fn idx -> lesson_step_fixture(%{lesson_id: lesson1.id, order: idx}) end)

      Content.add_user_selection(%{duration: 5, correct: 1, total: 3, user_id: user.id, lesson_id: lesson1.id, step_id: Enum.at(lesson_steps1, 0).id})
      Content.add_user_selection(%{duration: 5, correct: 2, total: 2, user_id: user.id, lesson_id: lesson1.id, step_id: Enum.at(lesson_steps1, 1).id})
      Content.add_user_selection(%{duration: 5, correct: 0, total: 1, user_id: user.id, lesson_id: lesson1.id, step_id: Enum.at(lesson_steps1, 2).id})

      assert {:ok, %UserLesson{} = user_lesson} = Content.mark_lesson_as_completed(user.id, lesson1.id, 20)
      assert user_lesson.user_id == user.id
      assert user_lesson.lesson_id == lesson1.id
      assert user_lesson.attempts == 1
      assert user_lesson.correct == 3
      assert user_lesson.total == 6
      assert user_lesson.duration == 20
    end
  end

  describe "course_completed?/2" do
    test "returns true if the course is completed" do
      user = user_fixture()
      course = course_fixture()
      generate_user_lesson(user.id, 0, course: course)

      assert Content.course_completed?(user, course) == true
    end

    test "returns false if the course is not completed" do
      user = user_fixture()
      course = course_fixture()
      generate_user_lesson(user.id, 0, course: course)
      lesson_fixture(%{course: course, published?: true})

      assert Content.course_completed?(user, course) == false
    end
  end

  describe "get_last_completed_course_slug/2" do
    test "returns the last completed course slug" do
      user = user_fixture()
      school = school_fixture()
      course1 = course_fixture(%{slug: "course-1", school: school})
      course2 = course_fixture(%{slug: "course-2", school: school})
      generate_user_lesson(user.id, 0, course: course1)
      generate_user_lesson(user.id, 0, course: course2)

      assert Content.get_last_completed_course_slug(school, user) == course2.slug
    end

    test "doesn't return courses from another school" do
      user = user_fixture()
      school1 = school_fixture()
      school2 = school_fixture()
      course1 = course_fixture(%{slug: "course-1", school: school1})
      course2 = course_fixture(%{slug: "course-2", school: school2})
      generate_user_lesson(user.id, 0, course: course1)
      generate_user_lesson(user.id, -1, course: course2)

      assert Content.get_last_completed_course_slug(school2, user) == course2.slug
    end
  end

  describe "get_last_edited_course/3" do
    test "returns the last edited course slug for a manager" do
      user = user_fixture()
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id})
      course2 = course_fixture(%{school_id: school.id})
      course3 = course_fixture(%{school_id: school.id})
      generate_user_lesson(user.id, 0, course: course1)
      generate_user_lesson(user.id, 0, course: course3)
      generate_user_lesson(user.id, 0, course: course2)

      assert Content.get_last_edited_course(school, user, :manager) == course2
    end

    test "when there are no lessons, use the last updated course" do
      user = user_fixture()
      school = school_fixture()
      course_fixture(%{school_id: school.id})
      course2 = course_fixture(%{school_id: school.id})

      assert Content.get_last_edited_course(school, user, :manager) == course2
    end

    test "returns nil when there are no courses" do
      user = user_fixture()
      school = school_fixture()

      assert Content.get_last_edited_course(school, user, :manager) == nil
    end

    test "returns the last course edited by a teacher" do
      user = user_fixture()
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id})
      course2 = course_fixture(%{school_id: school.id, preload: :school})
      course_fixture(%{school_id: school.id})

      course_user_fixture(%{course: course1, user: user, role: :teacher})
      course_user_fixture(%{course: course2, user: user, role: :teacher})

      assert Content.get_last_edited_course(school, user, :teacher) == course2
    end

    test "returns nil when there are no courses edited by a teacher" do
      user = user_fixture()
      school = school_fixture()
      course1 = course_fixture(%{school_id: school.id})

      course_user_fixture(%{course: course1, user: user, role: :student})

      assert Content.get_last_edited_course(school, user, :teacher) == nil
    end
  end

  describe "add_step_suggested_course/1" do
    test "adds a step suggested course" do
      step = lesson_step_fixture()
      course = course_fixture()

      assert {:ok, %StepSuggestedCourse{} = step_suggested_course} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course.id})
      assert step_suggested_course.lesson_step_id == step.id
      assert step_suggested_course.course_id == course.id
    end

    test "doesn't allow empty course_id" do
      step = lesson_step_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: nil})
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "doesn't allow empty lesson_step_id" do
      course = course_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Content.add_step_suggested_course(%{lesson_step_id: nil, course_id: course.id})
      assert "can't be blank" in errors_on(changeset).lesson_step_id
    end

    test "doesn't allow duplicate step suggested courses" do
      step = lesson_step_fixture()
      course = course_fixture()

      assert {:ok, %StepSuggestedCourse{}} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course.id})
      assert {:error, %Ecto.Changeset{} = changeset} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course.id})
      assert "has already been taken" in errors_on(changeset).lesson_step_id
    end
  end

  describe "delete_step_suggested_course/1" do
    test "deletes a step suggested course" do
      step = lesson_step_fixture()
      course = course_fixture()
      {:ok, %StepSuggestedCourse{} = step_suggested_course} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course.id})

      assert {:ok, %StepSuggestedCourse{}} = Content.delete_step_suggested_course(step_suggested_course.id)
      assert_raise Ecto.NoResultsError, fn -> Zoonk.Repo.get!(StepSuggestedCourse, step.id) end
    end
  end

  describe "list_step_suggested_courses/1" do
    test "returns a list of step suggested courses" do
      step = lesson_step_fixture()
      course1 = course_fixture()
      course2 = course_fixture()

      {:ok, %StepSuggestedCourse{} = step_suggested_course1} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course1.id})
      {:ok, %StepSuggestedCourse{} = step_suggested_course2} = Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course2.id})

      courses = Content.list_step_suggested_courses(step.id)
      assert Enum.at(courses, 0).id == step_suggested_course1.id
      assert Enum.at(courses, 1).id == step_suggested_course2.id
    end
  end

  describe "search_courses_by_school/2" do
    test "returns a list of courses" do
      school = school_fixture()
      course = course_fixture(%{school_id: school.id, name: "Course 123", published?: true, slug: "course_123"})
      course_fixture(%{name: "Course 123", slug: "course_123"})
      course_fixture(%{school_id: school.id, name: "Course 123", slug: "course_1234", published?: false})

      assert Content.search_courses_by_school(school.id, "course") == [course]
      assert Content.search_courses_by_school(school.id, "123") == [course]
      assert Content.search_courses_by_school(school.id, "course_123") == [course]
    end
  end
end
