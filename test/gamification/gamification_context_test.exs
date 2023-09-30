defmodule Uneebee.GamificationTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Gamification

  describe "learning_days_count/1" do
    test "calculates how many learning days a user has completed" do
      user = user_fixture()
      Enum.each(1..3, fn idx -> generate_user_lesson(user.id, -idx) end)
      assert Gamification.learning_days_count(user.id) == 3
    end
  end
end
