defmodule Stein.Timer do
  @moduledoc """
  Functions around daily timer processes
  """

  @type runs_at_opts() :: Keyword.t()

  @type milliseconds :: integer()

  alias Stein.Time

  @doc """
  Calculate the delay to the next daily cycle
  """
  @spec calculate_daily_cycle_delay(DateTime.t(), runs_at_opts()) :: milliseconds()
  def calculate_daily_cycle_delay(now, runs_at) do
    hour = Keyword.get(runs_at, :hour, 0)
    minute = Keyword.get(runs_at, :minute, 0)
    second = Keyword.get(runs_at, :second, 0)

    now
    |> Timex.set(hour: hour, minute: minute, second: second)
    |> maybe_shift_a_day(now)
    |> Timex.diff(now, :milliseconds)
  end

  defp maybe_shift_a_day(next_run, now) do
    case Time.before?(now, next_run) do
      true ->
        next_run

      false ->
        Timex.shift(next_run, days: 1)
    end
  end

  @doc """
  Calculate the delay to the next weekly cycle
  """
  @spec calculate_weekly_cycle_delay(DateTime.t(), runs_at_opts()) :: milliseconds()
  def calculate_weekly_cycle_delay(now, runs_at) do
    day = Keyword.get(runs_at, :day, 0)
    hour = Keyword.get(runs_at, :hour, 0)
    minute = Keyword.get(runs_at, :minute, 0)
    second = Keyword.get(runs_at, :second, 0)

    now
    |> Timex.set(hour: hour, minute: minute, second: second)
    |> shift_days(day)
    |> maybe_shift_a_week(now)
    |> Timex.diff(now, :milliseconds)
  end

  defp shift_days(now, day) do
    case Timex.weekday(now) > day do
      true ->
        # Shift into the next week
        # time to end of the week plus the day
        Timex.shift(now, days: day + (7 - Timex.weekday(now)))

      false ->
        # Shift ahead in this week
        Timex.shift(now, days: day - Timex.weekday(now))
    end
  end

  defp maybe_shift_a_week(next_run, now) do
    case Time.before?(now, next_run) do
      true ->
        next_run

      false ->
        Timex.shift(next_run, days: 7)
    end
  end
end
