defmodule Uneebee.OrganizationsTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Organizations
  alias Uneebee.Organizations.School
  alias Uneebee.Organizations.SchoolUser

  describe "change_school/2" do
    test "returns a school changeset" do
      school = school_fixture()
      assert %Ecto.Changeset{} = Organizations.change_school(school, %{})
    end

    test "email must have the @" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{email: "invalidgmail.com"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "email cannot have spaces" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{email: "invalid @gmail.com"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "email doesn't have more than 160 characters" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{email: String.duplicate("a", 160) <> "@gmail.com"})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "logo can start with /" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{logo: "/logo.png"})
      assert changeset.valid?
    end

    test "logo can start with https://" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{logo: "https://logo.png"})
      assert changeset.valid?
    end

    test "logo cannot start with http" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{logo: "http://logo.png"})
      assert "must start with / or https://" in errors_on(changeset).logo
    end

    test "logo cannot start with the image name" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{logo: "logo.png"})
      assert "must start with / or https://" in errors_on(changeset).logo
    end

    test "slug is unique" do
      school1 = school_fixture()
      school2 = school_fixture()
      changeset = Organizations.change_school(school1, %{slug: school2.slug})
      assert "has already been taken" in errors_on(changeset).slug
    end

    test "slug doesn't contain spaces" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{slug: "invalid slug"})
      assert "can only contain letters, numbers, dashes and underscores" in errors_on(changeset).slug
    end

    test "slug doesn't contain special characters" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{slug: "invalid@slug"})
      assert "can only contain letters, numbers, dashes and underscores" in errors_on(changeset).slug
    end

    test "slug doesn't contain accented characters" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{slug: "invalidáslug"})
      assert "can only contain letters, numbers, dashes and underscores" in errors_on(changeset).slug
    end

    test "must have an email" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{email: nil})
      assert "can't be blank" in errors_on(changeset).email
    end

    test "must have a name" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{name: nil})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "must have a slug" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{slug: nil})
      assert "can't be blank" in errors_on(changeset).slug
    end
  end

  describe "create_school/1" do
    test "with valid data creates a school" do
      valid_attrs = valid_school_attributes()

      assert {:ok, %School{} = school} = Organizations.create_school(valid_attrs)

      assert school.created_by_id == valid_attrs.created_by_id
      assert school.email == valid_attrs.email
      assert school.public? == valid_attrs.public?
      assert school.name == valid_attrs.name
      assert school.slug == valid_attrs.slug
    end

    test "with invalid data returns an error" do
      invalid_attrs = valid_school_attributes(%{email: "invalid"})
      assert {:error, %Ecto.Changeset{}} = Organizations.create_school(invalid_attrs)
    end

    test "cannot create a school without the created_by_id field" do
      valid_attrs = Map.delete(valid_school_attributes(), :created_by_id)
      assert {:error, %Ecto.Changeset{}} = Organizations.create_school(valid_attrs)
    end

    test "allow creating multiple domains with the same extension" do
      school_fixture(%{custom_domain: "uneebee.com"})
      attrs = valid_school_attributes(%{custom_domain: "khan.org"})

      assert {:ok, %School{} = school} = Organizations.create_school(attrs)
      assert school.custom_domain == attrs.custom_domain
    end

    test "cannot use a custom domain with a subdomain from another organization" do
      school_fixture(%{custom_domain: "uneebee.com"})
      school_fixture(%{custom_domain: "learning.harvard.edu"})

      attrs1 = valid_school_attributes(%{custom_domain: "nested.uneebee.com"})
      attrs2 = valid_school_attributes(%{custom_domain: "science.learning.harvard.edu"})

      assert {:error, %Ecto.Changeset{}} = Organizations.create_school(attrs1)
      assert {:error, %Ecto.Changeset{}} = Organizations.create_school(attrs2)
    end
  end

  describe "create_school_and_manager/2" do
    test "with valid data creates a school and a manager" do
      user = user_fixture()
      valid_attrs = valid_school_attributes(%{created_by_id: user.id})

      assert {:ok, %School{} = school} = Organizations.create_school_and_manager(user, valid_attrs)

      assert school.created_by_id == valid_attrs.created_by_id
      assert school.email == valid_attrs.email
      assert school.public? == valid_attrs.public?
      assert school.name == valid_attrs.name
      assert school.slug == valid_attrs.slug

      school_user = Organizations.get_school_user_by_slug_and_username(school.slug, user.username)

      assert school_user.role == :manager
      assert school_user.approved? == true
      assert school_user.approved_by_id == user.id
      assert school_user.school_id == school.id
      assert school_user.user_id == valid_attrs.created_by_id
    end

    test "with invalid data returns an error" do
      user = user_fixture()
      invalid_attrs = valid_school_attributes(%{email: "invalid", created_by_id: user.id})
      assert {:error, %Ecto.Changeset{}} = Organizations.create_school_and_manager(user, invalid_attrs)
    end

    test "cannot create a school without the created_by_id field" do
      user = user_fixture()
      valid_attrs = Map.delete(valid_school_attributes(), :created_by_id)
      assert {:error, %Ecto.Changeset{}} = Organizations.create_school_and_manager(user, valid_attrs)
    end
  end

  describe "update_school/2" do
    test "with valid data updates the school" do
      school = school_fixture()
      valid_attrs = %{name: "updated name", slug: "updated_slug_#{System.unique_integer()}"}

      assert {:ok, %School{} = updated_school} = Organizations.update_school(school, valid_attrs)

      assert updated_school.name == valid_attrs.name
      assert updated_school.slug == valid_attrs.slug
    end

    test "with invalid data returns an error" do
      school = school_fixture()
      invalid_attrs = valid_school_attributes(%{email: "invalid"})
      assert {:error, %Ecto.Changeset{}} = Organizations.update_school(school, invalid_attrs)
    end
  end

  describe "get_school_by_slug!/1" do
    test "returns the school with given id" do
      school = school_fixture()
      assert Organizations.get_school_by_slug!(school.slug) == school
    end

    test "raises an error if the school doesn't exist" do
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_school_by_slug!("invalid") end
    end
  end

  describe "is_school_configured?/0" do
    test "returns true if there's a school configured" do
      school_fixture()
      assert Organizations.school_configured?()
    end

    test "returns false if there's no school configured" do
      assert !Organizations.school_configured?()
    end
  end

  test "add a school student" do
    school = school_fixture()
    user = user_fixture()

    assert {:ok, %SchoolUser{} = school_user} = Organizations.create_school_user(school, user, %{role: :student})

    assert school_user.role == :student
    assert school_user.school_id == school.id
    assert school_user.user_id == user.id
  end

  test "add a school teacher" do
    school = school_fixture()
    user = user_fixture()

    assert {:ok, %SchoolUser{} = school_user} = Organizations.create_school_user(school, user, %{role: :teacher})

    assert school_user.role == :teacher
    assert school_user.school_id == school.id
    assert school_user.user_id == user.id
  end

  test "add a school manager" do
    school = school_fixture()
    user = user_fixture()

    assert {:ok, %SchoolUser{} = school_user} = Organizations.create_school_user(school, user, %{role: :manager})

    assert school_user.role == :manager
    assert school_user.school_id == school.id
    assert school_user.user_id == user.id
  end

  test "returns an error if the role is invalid" do
    school = school_fixture()
    user = user_fixture()

    assert {:error, %Ecto.Changeset{}} = Organizations.create_school_user(school, user, %{role: :invalid})
  end

  test "only adds a user if they haven't been added to the school yet" do
    school = school_fixture(%{username: "user-#{System.unique_integer()}"})
    %{user: user} = school_user_fixture(%{role: :teacher, school: school, preload: :user})

    assert {:error, %Ecto.Changeset{}} = Organizations.create_school_user(school, user, %{role: :student})

    school_user = Organizations.get_school_user_by_slug_and_username(school.slug, user.username)
    assert school_user.role == :teacher
  end

  describe "get_school_user_by_slug_and_username/2" do
    test "returns a school user" do
      school = school_fixture()
      user = user_fixture()
      school_user = school_user_fixture(%{school: school, user: user})

      assert Organizations.get_school_user_by_slug_and_username(school.slug, user.username) == school_user
    end
  end
end
