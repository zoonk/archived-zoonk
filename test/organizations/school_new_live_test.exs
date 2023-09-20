defmodule UneebeeWeb.NewSchoolLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Organizations

  @school_form "#school-form"

  describe "New school page (authenticated users)" do
    setup :register_and_log_in_user

    test "creates a school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      {:ok, _lv, html} =
        lv
        |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert html =~ "School created successfully"

      school = Organizations.get_school_by_slug!(attrs.slug)
      assert school.created_by_id == user.id
      assert school.name == attrs.name
    end

    test "renders error when slug is duplicated", %{conn: conn} do
      existing_school = school_fixture()
      {:ok, lv, _html} = live(conn, ~p"/schools/new")
      assert field_change(lv, %{slug: existing_school.slug}) =~ "has already been taken"
    end
  end

  describe "New school page (non-authenticated users)" do
    test "redirects to login page", %{conn: conn} do
      result = get(conn, ~p"/schools/new")
      assert redirected_to(result) =~ "/login"
    end
  end

  defp field_change(lv, changes) do
    lv |> element(@school_form) |> render_change(school: changes)
  end
end
