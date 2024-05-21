defmodule ZoonkWeb.SharedUtilitiesTest do
  use Zoonk.DataCase, async: true

  import ZoonkWeb.Shared.Utilities

  describe "round_currency/1" do
    test "rounds a currency when the decimal is 0" do
      assert round_currency(1.0) == "1"
      assert round_currency(1.1) == "1.10"
      assert round_currency(1.8) == "1.80"
      assert round_currency(1.99) == "1.99"
    end
  end
end
