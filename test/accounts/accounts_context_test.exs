defmodule Uneebee.AccountsTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Gamification
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserToken
  alias Uneebee.Content
  alias Uneebee.Gamification

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user_by_username/1" do
    test "does not return the user if the username does not exist" do
      refute Accounts.get_user_by_username("unknown")
    end

    test "returns the user if the username exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_username(user.username)
    end
  end

  describe "get_user_by_email_or_username/1" do
    test "does not return the user if the email or username does not exist" do
      refute Accounts.get_user_by_email_or_username("unknown")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_or_username(user.email)
    end

    test "returns the user if the username exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_or_username(user.username)
    end
  end

  describe "get_user_by_email_or_username_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_or_username_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_or_username_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_or_username_and_password(user.email, valid_user_password())
    end

    test "returns the user if the username and password are valid" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_or_username_and_password(user.username, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(-1) end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})
      assert %{password: ["can't be blank"], email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have a domain name", "must have the @ sign and no spaces"],
               password: ["at least one digit or punctuation character", "at least one upper case character"]
             } =
               errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      assert {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      assert {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = %{email: email} |> valid_user_attributes() |> Accounts.register_user()
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "create_guest_user/0" do
    test "creates a guest user" do
      assert {:ok, %User{guest?: true}} = Accounts.create_guest_user()
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:language, :username, :password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = valid_user_password()
      changeset = Accounts.change_user_registration(%User{}, valid_user_attributes(email: email, password: password))

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "change_user_settings/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_settings(%User{})
      assert changeset.required == [:username, :language]
    end
  end

  describe "update_user_settings/2" do
    test "updates the username when valid" do
      user = user_fixture()
      {:ok, updated_user} = Accounts.update_user_settings(user, %{username: "newusername"})
      assert updated_user.username == "newusername"
    end

    test "does not update the username when length is lower than 3 characters" do
      user = user_fixture()
      {:error, changeset} = Accounts.update_user_settings(user, %{username: "sh"})
      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "does not update the username when there's already another user with that same username" do
      user1 = user_fixture(username: "user1")
      user2 = user_fixture(username: "user2")

      {:error, changeset} = Accounts.update_user_settings(user2, %{username: user1.username})

      assert "has already been taken" in errors_on(changeset).username
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})
      assert %{email: ["must have a domain name", "must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()
      password = valid_user_password()

      {:error, changeset} = Accounts.apply_user_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})
      assert %{current_password: ["is invalid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_user_update_email_instructions(user, nil, "current@example.com", url) end)

      assert {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()
      token = extract_user_token(fn url -> Accounts.deliver_user_update_email_instructions(%{user | email: email}, nil, user.email, url) end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset = Accounts.change_user_password(%User{}, %{"password" => "ValidPassword123"})

      assert changeset.valid?
      assert get_change(changeset, :password) == "ValidPassword123"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} = Accounts.update_user_password(user, valid_user_password(), %{password: "not valid", password_confirmation: "another"})

      assert %{
               password: ["at least one digit or punctuation character", "at least one upper case character"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})
      assert %{current_password: ["is invalid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} = Accounts.update_user_password(user, valid_user_password(), %{password: "ValidPassword123"})

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "ValidPassword123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.update_user_password(user, valid_user_password(), %{password: "NewPassword123"})

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{token: user_token.token, user_id: user_fixture().id, context: "session"})
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()
      Accounts.delete_user(user)
      refute Accounts.get_user_by_email(user.email)
    end

    test "deletes all medals a user earned" do
      user = user_fixture()
      user_medal_fixture(%{user: user})

      assert Gamification.count_user_medals(user.id) == 1
      Accounts.delete_user(user)
      assert Gamification.count_user_medals(user.id) == 0
    end

    test "deletes all trophies a user earned" do
      user = user_fixture()
      user_trophy_fixture(%{user: user})

      assert Gamification.count_user_trophies(user.id) == 1
      Accounts.delete_user(user)
      assert Gamification.count_user_trophies(user.id) == 0
    end

    test "deletes all missions a user earned" do
      user = user_fixture()
      user_mission_fixture(%{user: user})

      assert Gamification.count_completed_missions(user.id) == 1
      Accounts.delete_user(user)
      assert Gamification.count_completed_missions(user.id) == 0
    end

    test "deletes all courses a user has joined" do
      user = user_fixture()
      course_user = course_user_fixture(%{user: user})

      assert Content.get_course_user_by_id(course_user.course_id, user.id)
      Accounts.delete_user(user)
      refute Content.get_course_user_by_id(course_user.course_id, user.id)
    end

    test "deletes all lessons a user has completed" do
      user = user_fixture()
      generate_user_lesson(user.id, 0, number_of_lessons: 1)

      assert Content.count_user_lessons(user.id) == 1
      Accounts.delete_user(user)
      assert Content.count_user_lessons(user.id) == 0
    end

    test "deletes all user selections" do
      user = user_fixture()
      lesson = lesson_fixture()
      step = lesson_step_fixture(%{lesson: lesson})
      option = step_option_fixture(%{lesson_step: step})

      Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option.id, lesson_id: lesson.id})
      assert length(Content.list_user_selections_by_lesson(user.id, lesson.id, 1)) == 1
      Accounts.delete_user(user)
      assert Content.list_user_selections_by_lesson(user.id, lesson.id, 1) == []
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      school = school_fixture(%{require_confirmation?: true})
      token = extract_user_token(fn url -> Accounts.deliver_user_confirmation_instructions(user, school, url) end)

      assert {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end

    test "doesn't send a confirmation email when school doesn't require confirmation", %{user: user} do
      school = school_fixture(%{require_confirmation?: false})
      assert {:error, :not_required} = Accounts.deliver_user_confirmation_instructions(user, school, "/")
    end
  end

  describe "confirm_user/1" do
    setup do
      user = user_fixture()
      token = extract_user_token(fn url -> Accounts.deliver_user_confirmation_instructions(user, nil, url) end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_user_reset_password_instructions(user, nil, url) end)

      assert {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()
      token = extract_user_token(fn url -> Accounts.deliver_user_reset_password_instructions(user, nil, url) end)
      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} = Accounts.reset_user_password(user, %{password: "not valid", password_confirmation: "another"})

      assert %{
               password: ["at least one digit or punctuation character", "at least one upper case character"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "NewPassword123"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "NewPassword123")
    end

    test "deletes all tokens for the given user", %{user: user} do
      Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "NewPassword123"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
