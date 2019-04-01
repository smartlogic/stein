defmodule Stein.TimerTest do
  use ExUnit.Case

  alias Stein.Timer

  describe "calculating the delay to the next run" do
    test "for the next cycle" do
      now =
        Timex.now()
        |> Timex.set([hour: 20, minute: 0, second: 0])
        |> DateTime.truncate(:second)

      delay = Timer.calculate_daily_cycle_delay(now, [hour: 6])

      assert delay == 36000000
    end

    test "process is rebooted same day but before cycle runs" do
      now =
        Timex.now()
        |> Timex.set([hour: 4, minute: 0, second: 0])
        |> DateTime.truncate(:second)

      delay = Timer.calculate_daily_cycle_delay(now, [hour: 6])

      assert delay == 3600 * 2 * 1000
    end
  end
end
