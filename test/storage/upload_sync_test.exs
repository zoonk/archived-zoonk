# we're running this tests separately because I didn't figure out how to get the PID of the Flame.call process:
# https://elixirforum.com/t/mocking-a-module-called-from-flame-call/65082/3
# This means we need to use :set_mox_global and it requires tests to run synchronously.
# To avoid disabling async in all our tests, I've created this test file that runs synchronously.
# If you know how to fix this, please open a PR. I'll be really grateful.
defmodule ZoonkWeb.UploadSyncTests do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: false

  import Mox
  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Storage
  import ZoonkWeb.TestHelpers.Upload

  alias Zoonk.Accounts
  alias Zoonk.Content
  alias Zoonk.Organizations
  alias Zoonk.Repo
  alias Zoonk.Storage.SchoolObject
  alias Zoonk.Storage.StorageAPIMock

  setup :set_mox_global
  setup :verify_on_exit!

  describe "upload sync" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "updates logo", %{conn: conn, school: school} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/logo")
      assert_file_upload(lv, "school_logo")

      assert Organizations.get_school_by_slug!(school.slug).logo == uploaded_file_name()
    end

    test "updates icon", %{conn: conn, school: school} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/icon")
      assert_file_upload(lv, "school_icon")

      assert Organizations.get_school_by_slug!(school.slug).icon == uploaded_file_name()
    end

    test "uploads avatar", %{conn: conn, user: user} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/avatar")

      assert user.avatar == nil

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("avatar")|)
      assert_file_upload(lv, "user_avatar")

      assert Accounts.get_user!(user.id).avatar == uploaded_file_name()
    end

    test "removes the older avatar when uploading a new one", %{conn: conn, school: school, user: user} do
      mock_storage()

      expect(StorageAPIMock, :delete, fn _ -> {:ok, %{}} end)

      old_file_name = "#{System.unique_integer()}.jpg"
      school_object_fixture(%{school: school, key: old_file_name})

      Accounts.update_user_settings(user, %{avatar: old_file_name})

      {:ok, lv, _html} = live(conn, ~p"/users/settings/avatar")

      assert_file_upload(lv, "user_avatar")

      assert Accounts.get_user!(user.id).avatar == uploaded_file_name()
      assert Repo.get_by(SchoolObject, key: old_file_name) == nil
    end

    test "uploads a cover image", %{conn: conn, course: course} do
      mock_storage()

      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      {:ok, updated_lv, _html} =
        lv
        |> element("a#lesson-cover-link", "Cover")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/cover")

      assert_file_upload(updated_lv, "lesson_cover")

      assert Content.get_lesson!(lesson.id).cover == uploaded_file_name()
    end

    test "updates the cover image", %{conn: conn, school: school, course: course} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/cover")

      assert has_element?(lv, ~s|li[aria-current="page"] a:fl-icontains("manage courses")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a:fl-icontains("cover")|)
      assert_file_upload(lv, "course_cover")

      assert Content.get_course_by_slug!(course.slug, school.id).cover == uploaded_file_name()
    end
  end
end
