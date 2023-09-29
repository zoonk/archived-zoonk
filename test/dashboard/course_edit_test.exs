defmodule UneebeeWeb.DashboardCourseEditLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content
  import UneebeeWeb.TestHelpers.Upload

  alias Uneebee.Content

  @course_form "#course-form"

  describe "/dashboard/c/edit/info (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      redirect_to_login_page(conn, school)
    end
  end

  describe "/dashboard/c/edit/info (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "can update the info form", %{conn: conn, school: school, course: course} do
      assert_info_form(conn, school, course)
    end

    test "the information menu is active", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/info")
      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("Information")|)
    end
  end

  describe "/dashboard/c/edit/info (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/edit/info") end)
    end
  end

  describe "/dashboard/c/edit/info (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/edit/info") end)
    end
  end

  describe "/dashboard/c/edit/info (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "can update the info form", %{conn: conn, school: school, course: course} do
      assert_info_form(conn, school, course)
    end
  end

  describe "/dashboard/c/edit/cover" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "updates the cover image", %{conn: conn, school: school, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/cover")

      assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("cover")|)
      assert_file_upload(lv, "course_cover")

      updated_course = Content.get_course_by_slug!(course.slug, school.id)
      assert String.starts_with?(updated_course.cover, "/uploads/")
    end
  end

  describe "/dashboard/c/edit/privacy" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "updates the privacy", %{conn: conn, school: school, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/privacy")

      assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("privacy")|)

      attrs = %{public?: false, published?: false}

      result = lv |> form(@course_form, course: attrs) |> render_submit()
      assert result =~ "Course updated successfully!"

      updated_course = Content.get_course_by_slug!(course.slug, school.id)
      assert updated_course.public? == attrs.public?
      assert updated_course.published? == attrs.published?
    end
  end

  describe "/dashboard/c/edit/delete" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "deletes the course", %{conn: conn, school: school, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/delete")

      assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("delete course")|)

      lv |> form("#delete-form", %{confirmation: "CONFIRM"}) |> render_submit()

      assert_raise Ecto.NoResultsError, fn -> Content.get_course_by_slug!(course.slug, school.id) end
    end

    test "doesn't delete if confirmation message doesn't match", %{conn: conn, school: school, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/delete")

      assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("delete course")|)

      result =
        lv
        |> form("#delete-form", %{confirmation: "WRONG"})
        |> render_submit()

      assert result =~ "Confirmation message does not match."

      assert Content.get_course_by_slug!(course.slug, school.id).name == course.name
    end
  end

  defp redirect_to_login_page(conn, school) do
    course = course_fixture(%{school_id: school.id})
    result = get(conn, ~p"/dashboard/c/#{course.slug}/edit/info")
    assert redirected_to(result) == "/users/login"
  end

  defp assert_info_form(conn, school, course) do
    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/info")

    assert_course_name(lv)
    assert_course_description(lv)
    assert_course_slug(lv, school)

    attrs = %{
      description: "new description",
      language: :pt,
      level: :advanced,
      name: "new name",
      slug: "new-slug"
    }

    result = lv |> form(@course_form, course: attrs) |> render_submit()
    assert result =~ "Course updated successfully!"

    updated_course = Content.get_course_by_slug!(attrs.slug, school.id)
    assert updated_course.description == attrs.description
    assert updated_course.language == attrs.language
    assert updated_course.level == attrs.level
    assert updated_course.name == attrs.name
    assert updated_course.slug == attrs.slug
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
