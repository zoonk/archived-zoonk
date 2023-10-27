defmodule Uneebee.OrganizationsTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Content
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

    test "privacy policy cannot start with http" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{privacy_policy: "http://privacy_policy.com"})
      assert "must start with https://" in errors_on(changeset).privacy_policy
    end

    test "privacy policy cannot start with /" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{privacy_policy: "/privacy_policy.com"})
      assert "must start with https://" in errors_on(changeset).privacy_policy
    end

    test "privacy policy can start with https://" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{privacy_policy: "https://privacy_policy.com"})
      assert changeset.valid?
    end

    test "terms of use cannot start with http" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{terms_of_use: "http://terms_of_use.com"})
      assert "must start with https://" in errors_on(changeset).terms_of_use
    end

    test "terms of use cannot start with /" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{terms_of_use: "/terms_of_use.com"})
      assert "must start with https://" in errors_on(changeset).terms_of_use
    end

    test "terms of use can start with https://" do
      school = school_fixture()
      changeset = Organizations.change_school(school, %{terms_of_use: "https://terms_of_use.com"})
      assert changeset.valid?
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

      school_user = Organizations.get_school_user(school.slug, user.username)

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

  describe "get_school!/1" do
    test "returns the school with given id" do
      school = school_fixture()
      assert Organizations.get_school!(school.id) == school
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

  describe "create_school_user/3" do
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
      school = school_fixture(%{slug: "user-#{System.unique_integer()}"})
      %{user: user} = school_user_fixture(%{role: :teacher, school: school, preload: :user})

      assert {:error, %Ecto.Changeset{}} = Organizations.create_school_user(school, user, %{role: :student})

      school_user = Organizations.get_school_user(school.slug, user.username)
      assert school_user.role == :teacher
    end
  end

  describe "update_school_user/2" do
    test "update a school user" do
      school = school_fixture()
      user = user_fixture()
      school_user = school_user_fixture(%{school: school, user: user, role: :teacher})

      assert {:ok, %SchoolUser{} = updated_school_user} = Organizations.update_school_user(school_user, %{role: :manager})

      assert updated_school_user.role == :manager
      assert updated_school_user.school_id == school.id
      assert updated_school_user.user_id == user.id
    end

    test "returns an error if the role is invalid" do
      school = school_fixture()
      user = user_fixture()
      school_user = school_user_fixture(%{school: school, user: user})

      assert {:error, %Ecto.Changeset{}} = Organizations.update_school_user(school_user, %{role: :invalid})
    end
  end

  describe "get_school_user/2" do
    test "returns a school user" do
      school = school_fixture(%{slug: "user-#{System.unique_integer()}"})
      %{user: user} = school_user_fixture(%{school: school, preload: :user})

      school_user = Organizations.get_school_user(school.slug, user.username)

      assert school_user.user.first_name == user.first_name
      assert school_user.school.name == school.name
    end
  end

  describe "get_school_by_host!/1" do
    test "returns the school depending on the subdomain value" do
      school1 = school_fixture(%{custom_domain: "uneebee.com"})
      school2 = school_fixture(%{slug: "unisc", school_id: school1.id})

      assert Organizations.get_school_by_host!("unisc.uneebee.com") == school2
    end

    test "raises if the slug doesn't match the parent school" do
      school_fixture(%{custom_domain: "uneebee.com"})
      school2 = school_fixture(%{custom_domain: "harvard.edu"})
      school3 = school_fixture(%{slug: "unisc", school_id: school2.id})

      assert_raise Ecto.NoResultsError, fn -> Organizations.get_school_by_host!("unisc.uneebee.com") end
      assert Organizations.get_school_by_host!("unisc.harvard.edu") == school3
    end

    test "returns the school depending on the subdomain value of a custom domain" do
      school1 = school_fixture(%{custom_domain: "interactive.harvard.edu"})
      school2 = school_fixture(%{slug: "business", school_id: school1.id})

      assert Organizations.get_school_by_host!("business.interactive.harvard.edu") == school2
    end

    test "returns the school depending on the custom domain value" do
      custom_domain = "interactive.rug.nl"
      school = school_fixture(%{custom_domain: custom_domain})

      assert Organizations.get_school_by_host!(custom_domain) == school
    end

    test "returns nil when the custom domain doesn't exist but it matches a slug" do
      school_fixture(%{slug: "uneebee", custom_domain: "uneebee.com"})
      assert Organizations.get_school_by_host!("uneebee.test") == nil
    end
  end

  describe "get_school_users_count/2" do
    test "returns the number of users in a school" do
      school = school_fixture()
      Enum.each(1..4, fn _idx -> school_user_fixture(%{school: school, role: :student}) end)
      Enum.each(1..3, fn _idx -> school_user_fixture(%{school: school, role: :teacher}) end)
      school_user_fixture(%{school: school, role: :manager})

      assert Organizations.get_school_users_count(school, :student) == 4
      assert Organizations.get_school_users_count(school, :teacher) == 3
      assert Organizations.get_school_users_count(school, :manager) == 1
    end
  end

  describe "list_school_users_by_role/2" do
    test "list all managers from a school" do
      user = user_fixture()
      school = school_fixture()
      school_user = school_user_fixture(%{user: user, school: school, role: :manager, preload: [:approved_by, :user]})
      school_user_fixture(%{school: school, role: :teacher})

      assert Organizations.list_school_users_by_role(school, :manager) == [school_user]
    end

    test "shows managers pending approval first" do
      user1 = user_fixture()
      user2 = user_fixture()
      school = school_fixture()

      approved_user = school_user_fixture(%{user: user1, school: school, role: :manager, preload: [:user, :approved_by]})
      not_approved_user = school_user_fixture(%{user: user2, school: school, role: :manager, approved?: false, preload: [:user, :approved_by]})

      assert Organizations.list_school_users_by_role(school, :manager) == [not_approved_user, approved_user]
    end

    test "list all teachers from a school" do
      school = school_fixture()
      teacher_user = user_fixture()
      teacher_school_user = school_user_fixture(%{user: teacher_user, school: school, role: :teacher, preload: [:user, :approved_by]})
      school_user_fixture(%{school: school})

      assert Organizations.list_school_users_by_role(school, :teacher) == [teacher_school_user]
    end

    test "shows teachers pending approval first" do
      school = school_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      approved_user = school_user_fixture(%{user: user1, school: school, role: :teacher, preload: [:user, :approved_by]})
      not_approved_user = school_user_fixture(%{user: user2, school: school, role: :teacher, approved?: false, preload: [:user, :approved_by]})

      assert Organizations.list_school_users_by_role(school, :teacher) == [not_approved_user, approved_user]
    end
  end

  describe "approve_school_user/2" do
    test "approves a school user" do
      manager_user = user_fixture()
      school = school_fixture()
      school_user_fixture(%{user: manager_user, school: school, role: :manager})
      school_user = school_user_fixture(%{school: school, approved?: false})

      assert {:ok, %SchoolUser{} = school_user} = Organizations.approve_school_user(school_user.id, manager_user.id)
      assert school_user.approved?
    end
  end

  describe "delete_school_user/1" do
    test "deletes the school user and all course users" do
      school1 = school_fixture()
      school2 = school_fixture()

      user1 = user_fixture()
      user2 = user_fixture()

      school_user = school_user_fixture(%{user: user1, school: school1})
      school_user_fixture(%{user: user2, school: school2})

      course1 = course_fixture(%{school_id: school1.id})
      course_user_fixture(%{course_id: course1.id, user: user1})
      course_user_fixture(%{course_id: course1.id, user: user2})

      course2 = course_fixture(%{school_id: school2.id})
      course_user_fixture(%{course_id: course2.id, user: user1})

      # Makes sure the course user actually exists to avoid false positives.
      assert Content.get_course_user_by_id(course1.id, user1.id) != nil
      assert Content.get_course_user_by_id(course1.id, user2.id) != nil

      assert {:ok, _deleted} = Organizations.delete_school_user(school_user.id)
      assert Organizations.get_school_user(school1.slug, user1.username) == nil
      assert Content.get_course_user_by_id(course1.id, user1.id) == nil

      # Other course users should not be deleted.
      assert Content.get_course_user_by_id(course1.id, user2.id) != nil

      # Should not delete course users from other schools.
      assert Content.get_course_user_by_id(course2.id, user1.id) != nil
    end
  end

  describe "get_courses_count/1" do
    test "returns the number of courses" do
      school = school_fixture()
      Enum.each(1..4, fn _idx -> course_fixture(%{school_id: school.id}) end)
      assert Organizations.get_courses_count(school) == 4
    end
  end
end
