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

    test "allows to create a white label school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()
      conn = Map.put(conn, :host, attrs.custom_domain)

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      lv
      |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug, kind: "white_label"})
      |> render_submit()
      |> follow_redirect(conn, ~p"/dashboard")

      school = Organizations.get_school_by_slug!(attrs.slug)
      assert school.created_by_id == user.id
      assert school.name == attrs.name
      assert school.kind == :white_label
    end

    test "allows to create a SaaS school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()
      conn = Map.put(conn, :host, attrs.custom_domain)

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      lv
      |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug, kind: "saas"})
      |> render_submit()
      |> follow_redirect(conn, ~p"/dashboard")

      school = Organizations.get_school_by_slug!(attrs.slug)
      assert school.created_by_id == user.id
      assert school.name == attrs.name
      assert school.kind == :saas
    end

    test "allows to create a marketplace school", %{conn: conn, user: user} do
      attrs = valid_school_attributes()
      conn = Map.put(conn, :host, attrs.custom_domain)

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      lv
      |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug, kind: "marketplace"})
      |> render_submit()
      |> follow_redirect(conn, ~p"/dashboard")

      school = Organizations.get_school_by_slug!(attrs.slug)
      assert school.created_by_id == user.id
      assert school.name == attrs.name
      assert school.kind == :marketplace
    end
  end

  describe "New school page (authenticated users, school configured)" do
    setup :app_setup

    test "renders an error if the school is configured and it's a white label school", %{conn: conn} do
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

  describe "New school (SaaS app)" do
    setup do
      app_setup(%{conn: build_conn()}, school_kind: :saas)
    end

    test "allows to create a school", %{conn: conn, school: school, user: user} do
      attrs = valid_school_attributes()

      {:ok, lv, _html} = live(conn, ~p"/schools/new")

      refute has_element?(lv, ~s|select[id="school_kind"]|)

      {:error, {:redirect, %{to: redirected_url}}} =
        lv
        |> form(@school_form, school: %{name: attrs.name, email: attrs.email, slug: attrs.slug})
        |> render_submit()

      assert redirected_url == "https://#{attrs.slug}.#{school.custom_domain}/dashboard"

      child_school = Organizations.get_school_by_slug!(attrs.slug)
      assert child_school.created_by_id == user.id
      assert child_school.name == attrs.name
      assert child_school.kind == :white_label
      assert child_school.school_id == school.id
      refute child_school.public?
    end
  end
end
