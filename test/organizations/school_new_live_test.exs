defmodule UneebeeWeb.NewSchoolLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Organizations

  @school_form "#school-form"

  describe "New school page (authenticated users, school not configured)" do
    setup :register_and_log_in_user

    test "creates a school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()
      conn = Map.put(conn, :host, attrs.custom_domain)

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

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :manager
      assert school_user.approved? == true
    end
  end

  describe "New school page (authenticated users, school configured)" do
    setup :app_setup

    test "renders an error if the school is configured", %{conn: conn} do
      school_fixture()
      assert_error_sent 403, fn -> get(conn, ~p"/schools/new") end
    end
  end

  describe "New school page (non-authenticated users)" do
    test "redirects to login page", %{conn: conn} do
      result = get(conn, ~p"/schools/new")
      assert redirected_to(result) =~ "/login"
    end
  end
end
