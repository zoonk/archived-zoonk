defmodule Uneebee.UserUtilsTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts

  alias Uneebee.Accounts.UserUtils

  describe "full_name/1" do
    test "returns the user's full name" do
      user = user_fixture(%{first_name: "John", last_name: "Doe"})
      assert UserUtils.full_name(user) == "John Doe"
    end

    test "returns the user's first name" do
      user = user_fixture(%{first_name: "John", last_name: nil})
      assert UserUtils.full_name(user) == "John"
    end

    test "returns the user's last name" do
      user = user_fixture(%{first_name: nil, last_name: "Doe"})
      assert UserUtils.full_name(user) == "Doe"
    end

    test "returns the user's username" do
      user = user_fixture(%{first_name: nil, last_name: nil, username: "johndoe"})
      assert UserUtils.full_name(user) == "johndoe"
    end
  end
end
