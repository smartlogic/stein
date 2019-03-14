defmodule Stein do
  @moduledoc """
  Documentation for Stein.
  """

  @typedoc """
  Your Ecto repo module
  """
  @type repo() :: Ecto.Repo.t()

  @type uuid() :: String.t()

  @doc false
  def config({:system, name}), do: System.get_env(name)

  def config(value), do: value
end
