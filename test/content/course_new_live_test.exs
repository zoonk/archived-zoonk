defmodule ZoonkWeb.CourseNewLiveTest do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content
  import ZoonkWeb.Shared.Slug

  alias Zoonk.Accounts
  alias Zoonk.Content

  @course_form "#course-form"

  describe "/dashboard/courses/new (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/courses/new")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/courses/new (student)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/courses/new") end)
    end
  end

  describe "/dashboard/courses/new (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "creates a course", %{conn: conn, school: school} do
      assert_create_course(conn, school)
    end

    test "uses the user language as default value for the course", %{conn: conn, school: school, user: user} do
      Accounts.update_user_settings(user, %{language: :pt})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/courses/new")

      attrs = valid_course_attributes()

      lv |> form(@course_form, course: %{name: attrs.name, description: attrs.description, slug: attrs.slug}) |> render_submit()

      course = Content.get_course_by_slug!(attrs.slug, school.id)
      assert course.language == :pt
    end
  end

  describe "/dashboard/courses/new (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "creates a course", %{conn: conn, school: school} do
      assert_create_course(conn, school)
    end
  end

  defp assert_create_course(conn, school) do
    {:ok, lv, _html} = live(conn, ~p"/dashboard/courses/new")

    assert_course_name(lv)
    assert_course_description(lv)
    assert_course_slug(lv, school)

    attrs = valid_course_attributes(%{school_id: school.id})
    slug = slug(attrs.name)

    {:ok, _lv, _html} =
      lv
      |> form(@course_form, course: %{name: attrs.name, description: attrs.description, level: :expert, slug: slug})
      |> render_submit()
      |> follow_redirect(conn, ~p"/dashboard/c/#{slug}")

    course = Content.get_course_by_slug!(slug, school.id)

    assert course.published? == false
    assert course.language == :en
    assert course.school_id == school.id
    assert course.name == attrs.name
    assert course.description == attrs.description
    assert course.level == :expert
  end

  defp assert_course_name(lv) do
    lv |> element(@course_form) |> render_change(course: %{name: ""})

    assert has_element?(lv, ~s|div[phx-feedback-for="course[name]"] p:fl-icontains("can't be blank")|)
  end

  defp assert_course_description(lv) do
    lv |> element(@course_form) |> render_change(course: %{description: ""})

    assert has_element?(lv, ~s|div[phx-feedback-for="course[description]"] p:fl-icontains("can't be blank")|)
  end

  defp assert_course_slug(lv, school) do
    course = course_fixture(%{school_id: school.id})

    assert_slug_el(lv, "", "can't be blank")
    assert_slug_el(lv, course.slug, "has already been taken")
    assert_slug_el(lv, "with spaces", "can only contain letters,")
    assert_slug_el(lv, "with-special-characters!", "can only contain letters,")
    assert_slug_el(lv, "with-áccented-characters", "can only contain letters,")
  end

  defp assert_slug_el(lv, slug, expected) do
    lv |> element(@course_form) |> render_change(course: %{slug: slug})

    assert has_element?(lv, ~s|div[phx-feedback-for="course[slug]"] p:fl-icontains("#{expected}")|)
  end
end
