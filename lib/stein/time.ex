defmodule Stein.Time do
  @moduledoc """
  Helpers for dealing with time
  """

  @doc """
  Get the current time
  """
  @spec now() :: DateTime.t()
  def now() do
    :os.system_time()
    |> DateTime.from_unix!(:native)
    |> DateTime.truncate(:second)
  end

  @doc """
  Determine if a time is after another time
  """
  @spec after?(DateTime.t(), DateTime.t()) :: boolean()
  def after?(_time, nil), do: false

  def after?(time, other_time) do
    case DateTime.compare(time, other_time) do
      :gt ->
        true

      _ ->
        false
    end
  end

  @doc """
  Check if a time is before another time
  """
  def before?(time, other_time) do
    case DateTime.compare(time, other_time) do
      :lt ->
        true

      _ ->
        false
    end
  end
end
