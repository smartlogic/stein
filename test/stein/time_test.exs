defmodule Stein.TimeTest do
  use ExUnit.Case

  alias Stein.Time

  describe "after?" do
    test "false" do
      now = Timex.set(Time.now(), [hour: 20, minute: 0, second: 0])
      then = Timex.set(Time.now(), [hour: 21, minute: 0, second: 0])

      refute Time.after?(now, then)
    end

    test "true" do
      now = Timex.set(Time.now(), [hour: 20, minute: 0, second: 0])
      then = Timex.set(Time.now(), [hour: 21, minute: 0, second: 0])

      assert Time.after?(then, now)
    end
  end

  describe "before?" do
    test "true" do
      now = Timex.set(Time.now(), [hour: 20, minute: 0, second: 0])
      then = Timex.set(Time.now(), [hour: 21, minute: 0, second: 0])

      assert Time.before?(now, then)
    end

    test "false" do
      now = Timex.set(Time.now(), [hour: 20, minute: 0, second: 0])
      then = Timex.set(Time.now(), [hour: 21, minute: 0, second: 0])

      refute Time.before?(then, now)
    end
  end
end
