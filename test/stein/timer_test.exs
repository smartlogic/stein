defmodule Stein.TimerTest do
  use ExUnit.Case

  alias Stein.Timer

  describe "calculating the delay to the next daily run" do
    test "for the next cycle" do
      now =
        Timex.now()
        |> Timex.set(hour: 20, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_daily_cycle_delay(now, hour: 6)

      assert delay == 36_000_000
    end

    test "the current time is the same time it's supposed to run, pick tomorrow" do
      Enum.map(0..59, fn second ->
        now =
          Timex.now()
          |> Timex.set(hour: 6, minute: 0, second: second)
          |> DateTime.truncate(:second)

        delay = Timer.calculate_daily_cycle_delay(now, hour: 6, minute: 0, second: second)

        assert delay == 3600 * 24 * 1000
      end)
    end

    test "same hour and minute but offset by seconds" do
      now =
        Timex.now()
        |> Timex.set(hour: 6, minute: 0, second: 15)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_daily_cycle_delay(now, hour: 6)

      assert delay == (3600 * 24 - 15) * 1000
    end

    test "process is rebooted same day but before cycle runs" do
      now =
        Timex.now()
        |> Timex.set(hour: 4, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_daily_cycle_delay(now, hour: 6)

      assert delay == 3600 * 2 * 1000
    end
  end

  describe "calculating the delay to the next weekly run" do
    test "for the next cycle" do
      # now is thursday, shift to monday

      now =
        Timex.now()
        |> Timex.set(year: 2019, month: 10, day: 24, hour: 10, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_weekly_cycle_delay(now, day: 1, hour: 11)

      # four days and an hour in milliseconds
      assert delay == 4 * 24 * 3600 * 1000 + 3600 * 1000
    end

    test "for the current cycle same day" do
      # now is thursday, shift to saturday

      now =
        Timex.now()
        |> Timex.set(year: 2019, month: 10, day: 24, hour: 10, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_weekly_cycle_delay(now, day: 4, hour: 11)

      # an hour in milliseconds
      assert delay == 3600 * 1000
    end

    test "for the current cycle same day, passed the timer" do
      # now is thursday, shift to saturday

      now =
        Timex.now()
        |> Timex.set(year: 2019, month: 10, day: 24, hour: 12, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_weekly_cycle_delay(now, day: 4, hour: 11)

      # six days, 23 hours in milliseconds
      assert delay == 6 * 24 * 3600 * 1000 + 23 * 3600 * 1000
    end

    test "for the current cycle" do
      # now is thursday, shift to saturday

      now =
        Timex.now()
        |> Timex.set(year: 2019, month: 10, day: 24, hour: 10, minute: 0, second: 0)
        |> DateTime.truncate(:second)

      delay = Timer.calculate_weekly_cycle_delay(now, day: 6, hour: 11)

      # two days and an hour in milliseconds
      assert delay == 2 * 24 * 3600 * 1000 + 3600 * 1000
    end

    test "the current time is the same time it's supposed to run, pick next week" do
      # now is thursday, shift to next thursday

      Enum.map(0..59, fn second ->
        now =
          Timex.now()
          |> Timex.set(year: 2019, month: 10, day: 24, hour: 10, minute: 0, second: second)
          |> DateTime.truncate(:second)

        delay =
          Timer.calculate_weekly_cycle_delay(now, day: 4, hour: 10, minute: 0, second: second)

        assert delay == 7 * 3600 * 24 * 1000
      end)
    end
  end
end
