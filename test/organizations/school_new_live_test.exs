defmodule ZoonkWeb.NewSchoolLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Organizations

  @school_form "#school-form"

  describe "New school page (authenticated users, school not configured)" do
    setup :register_and_log_in_user

    test "creates a school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()
      conn = Map.put(conn, :host, attrs.custom_domain)

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      lv
      |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug})
      |> render_submit()
      |> follow_redirect(conn, ~p"/dashboard")

      school = Organizations.get_school_by_slug!(attrs.slug)
      assert school.created_by_id == user.id
      assert school.name == attrs.name
      assert school.public?

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :manager
      assert school_user.approved? == true
    end
  end

  describe "New school page (authenticated users, school configured)" do
    setup :app_setup

    test "renders an error if the school is configured and it's a child school", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id})
      conn = Map.put(conn, :host, "#{child_school.slug}.#{school.custom_domain}")

      assert_error_sent 403, fn -> get(conn, ~p"/schools/new") end
    end
  end

  describe "New school page (non-authenticated users)" do
    test "redirects to login page", %{conn: conn} do
      result = get(conn, ~p"/schools/new")
      assert redirected_to(result) =~ "/login"
    end
  end

  describe "New school page (guest user)" do
    setup do
      set_school_with_guest_user(%{conn: build_conn()})
    end

    test "redirects to the setup page", %{conn: conn} do
      result = get(conn, ~p"/schools/new")
      assert redirected_to(result) =~ "/users/settings"
    end
  end
end
