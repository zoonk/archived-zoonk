defmodule Zoonk.StorageContextTest do
  use Zoonk.DataCase, async: true

  import Mox
  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Organizations
  import Zoonk.Fixtures.Storage

  alias Zoonk.Storage
  alias Zoonk.Storage.SchoolObject
  alias Zoonk.Storage.StorageAPIMock

  setup :verify_on_exit!

  describe "storage context" do
    test "create_school_object/1" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: 10, school_id: school.id}
      assert {:ok, %SchoolObject{}} = Storage.create_school_object(attrs)
    end

    test "requires a unique key" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: 10, school_id: school.id}

      assert {:ok, %SchoolObject{}} = Storage.create_school_object(attrs)
      assert {:error, %Ecto.Changeset{}} = Storage.create_school_object(attrs)
    end

    test "requires a school_id" do
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: 10}
      assert {:error, %Ecto.Changeset{}} = Storage.create_school_object(attrs)
    end

    test "requires a content_type" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", size_kb: 10, school_id: school.id}
      assert {:error, %Ecto.Changeset{}} = Storage.create_school_object(attrs)
    end

    test "requires a size_kb" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", school_id: school.id}
      assert {:error, %Ecto.Changeset{}} = Storage.create_school_object(attrs)
    end

    test "size_kb is an integer" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: "test", school_id: school.id}
      assert {:error, %Ecto.Changeset{}} = Storage.create_school_object(attrs)
    end
  end

  describe "update_school_object/2" do
    test "updates the school_object" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: 10, school_id: school.id}

      assert {:ok, %SchoolObject{}} = Storage.create_school_object(attrs)
      assert {:ok, %SchoolObject{}} = Storage.update_school_object(attrs.key, %{content_type: "image/png"})
    end

    test "deletes the school_object" do
      school = school_fixture()
      attrs = %{key: "#{System.unique_integer()}", content_type: "image/jpeg", size_kb: 10, school_id: school.id}

      assert {:ok, %SchoolObject{id: id}} = Storage.create_school_object(attrs)
      assert Repo.get(SchoolObject, id) != nil

      assert {:ok, %SchoolObject{}} = Storage.delete_school_object(attrs.key)
      assert Repo.get(SchoolObject, id) == nil
    end
  end

  describe "delete/1" do
    test "deletes the school_object after removing an image" do
      expect(StorageAPIMock, :delete, fn _ -> {:ok, %{}} end)

      school_object = school_object_fixture()
      assert {:ok, %SchoolObject{}} = Storage.delete_object(school_object.key)
      assert Repo.get(SchoolObject, school_object.id) == nil
    end

    test "returns an error if the storage api returns an error" do
      expect(StorageAPIMock, :delete, fn _ -> {:error, %{}} end)

      school_object = school_object_fixture()
      assert {:error, %{}} = Storage.delete_object(school_object.key)
    end
  end

  describe "presigned_url/2" do
    test "returns a presigned url" do
      school = school_fixture()
      file_name = "#{System.unique_integer()}.png"
      entry = %{client_name: file_name, client_type: "image/png", client_size: 456_123}
      folder = "#{school.id}/schools/#{school.id}/logo"
      key = "#{folder}/#{file_name}"

      expect(StorageAPIMock, :presigned_url, fn _entry, _folder -> {"https://...", key} end)

      {url, returned_key} = Storage.presigned_url(entry, folder)
      assert url == "https://..."
      assert returned_key == key
    end

    test "creates a school object after presigned url" do
      course = course_fixture()
      file_name = "#{System.unique_integer()}.png"
      entry = %{client_name: file_name, client_type: "image/png", client_size: 456_123}
      folder = "#{course.school_id}/courses/#{course.id}/logo"
      key = "#{folder}/#{file_name}"

      expect(StorageAPIMock, :presigned_url, fn _entry, _folder -> {"https://...", key} end)

      assert {url, returned_key} = Storage.presigned_url(entry, folder)
      assert url == "https://..."
      assert returned_key == key

      school_object = Repo.get_by(SchoolObject, key: key)

      assert school_object.content_type == "image/png"
      assert school_object.size_kb == div(456_123, 1024)
      assert school_object.key == key
      assert school_object.school_id == course.school_id
      assert school_object.course_id == course.id
    end
  end
end
