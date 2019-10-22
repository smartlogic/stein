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
    minute = Keyword.get(runs_at, :mintue, 0)
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
end
