defmodule UneebeeWeb.CourseListLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  describe "/courses (public school, non-authenticated users)" do
    setup :set_school

    test "renders the app menu", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/courses")
      refute has_element?(lv, ~s"#courses-teaching")
      refute has_element?(lv, ~s"#courses-learning")
    end

    test "lists public courses from the host school", %{conn: conn, school: school} do
      assert_course_list(conn, school, nil)
    end

    test "doesn't show courses in another language", %{conn: conn, school: school} do
      valid_course = course_fixture(%{school_id: school.id, language: :en})
      other_language_course = course_fixture(%{school_id: school.id, language: :pt})

      {:ok, lv, _html} = live(conn, ~p"/courses")

      refute has_element?(lv, get_course_el(other_language_course))
      assert has_element?(lv, get_course_el(valid_course))
    end
  end

  describe "/courses (private school, non-authenticated users)" do
    setup do
      set_school(%{conn: build_conn()}, %{public?: false})
    end

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/courses")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/courses (public school, students, approved)" do
    setup :app_setup

    test "lists public courses from the host school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  describe "/courses (private school, students, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false)
    end

    test "lists public courses from the host school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  describe "/courses (private school, students, not approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :pending)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/courses") end)
    end
  end

  describe "/courses (public, teachers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  describe "/courses (private, teachers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :teacher)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  describe "/courses (public, managers, approved)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  describe "/courses (private, managers)" do
    setup do
      app_setup(%{conn: build_conn()}, public_school?: false, school_user: :manager)
    end

    test "lists all courses from the selected school", %{conn: conn, school: school, user: user} do
      assert_course_list(conn, school, user)
    end
  end

  defp course_el(id, course), do: ~s|#courses-#{id} a[href="/c/#{course.slug}"]|
  defp get_course_el(course), do: course_el("list", course)
  defp get_course_learning_el(course), do: course_el("learning", course)

  defp assert_course_list(conn, school, user) do
    assert_public_courses(conn, school)

    if user do
      assert_learning_courses(conn, school, user)
    end
  end

  defp assert_public_courses(conn, school) do
    # It shouldn't display unpublished courses.
    unpublished_course = course_fixture(%{school_id: school.id, published?: false})

    # It shouldn't display private courses
    private_course = course_fixture(%{school_id: school.id, published?: true, public?: false})

    # It should display published courses from the selected school.
    published_course = course_fixture(%{school_id: school.id, published?: true})

    {:ok, lv, _html} = live(conn, ~p"/courses")

    refute has_element?(lv, get_course_el(unpublished_course))
    refute has_element?(lv, get_course_el(private_course))
    assert has_element?(lv, get_course_el(published_course))
  end

  defp assert_learning_courses(conn, school, user) do
    # Private course should be on the learning list
    private_course = course_fixture(%{school_id: school.id, published?: true, public?: false})
    course_user_fixture(%{user: user, course: private_course, role: :student})

    # Public course should be on the learning list
    public_course = course_fixture(%{school_id: school.id, published?: true, public?: true})
    course_user_fixture(%{user: user, course: public_course, role: :student})

    # Courses not enrolled in shouldn't be on the learning list
    other_course = course_fixture(%{school_id: school.id, published?: true, public?: true})

    {:ok, lv, _html} = live(conn, ~p"/courses")

    assert has_element?(lv, get_course_learning_el(private_course))
    assert has_element?(lv, get_course_learning_el(public_course))
    refute has_element?(lv, get_course_learning_el(other_course))
  end
end
