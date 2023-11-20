defmodule UneebeeWeb.SchoolUpdateLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations
  import UneebeeWeb.TestHelpers.Upload

  alias Uneebee.Organizations

  @school_form "#school-form"

  describe "Edit school data" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "updates logo", %{conn: conn, school: school} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/logo")
      assert_file_upload(lv, "school_logo")

      updated_school = Organizations.get_school_by_slug!(school.slug)
      assert String.starts_with?(updated_school.logo, "/uploads/")
    end

    test "updates slug", %{conn: conn, school: school} do
      existing_school = school_fixture()
      new_slug = "new_#{System.unique_integer()}"

      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/settings")

      assert has_element?(lv, ~s|input[name="school[slug]"][value="#{school.slug}"]|)
      assert field_change(lv, %{slug: ""}) =~ "can&#39;t be blank"
      assert field_change(lv, %{slug: existing_school.slug}) =~ "has already been taken"

      assert lv
             |> form(@school_form, school: %{slug: new_slug})
             |> render_submit() =~ "School updated successfully"

      assert Organizations.get_school_by_slug!(new_slug).slug == new_slug
    end

    test "updates information", %{conn: conn, school: school} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/settings")

      new_name = "New school name"
      new_email = "new@example.com"

      assert has_element?(lv, ~s|input[name="school[name]"][value="#{school.name}"]|)
      assert has_element?(lv, ~s|input[name="school[email]"][value="#{school.email}"]|)

      assert field_change(lv, %{name: ""}) =~ "can&#39;t be blank"
      assert field_change(lv, %{email: ""}) =~ "can&#39;t be blank"
      assert field_change(lv, %{email: "marieatgmail.com"}) =~ "must have the @ sign and no spaces"
      assert field_change(lv, %{email: "marie@gmail. com"}) =~ "must have the @ sign and no spaces"

      assert lv
             |> form(@school_form, school: %{name: new_name, email: new_email})
             |> render_submit() =~ "School updated successfully"

      updated_school = Organizations.get_school_by_slug!(school.slug)
      assert updated_school.name == new_name
      assert updated_school.email == new_email
    end

    test "updates the require_confirmation? field", %{conn: conn, school: school} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/settings")

      assert has_element?(lv, ~s|input[name="school[require_confirmation?]"][value="false"]|)

      assert lv
             |> form(@school_form, school: %{"require_confirmation?" => "false"})
             |> render_submit() =~ "School updated successfully"

      updated_school = Organizations.get_school_by_slug!(school.slug)
      assert updated_school.require_confirmation? == false
    end
  end

  describe "/dashboard/edit (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/edit/settings")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/edit (students)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/edit/settings") end
    end
  end

  describe "/dashboard/edit (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/edit/settings") end
    end
  end

  defp field_change(lv, changes) do
    lv |> element(@school_form) |> render_change(school: changes)
  end
end
