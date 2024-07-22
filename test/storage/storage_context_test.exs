defmodule Zoonk.StorageContextTest do
  use Zoonk.DataCase, async: true

  import Mox
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
end
