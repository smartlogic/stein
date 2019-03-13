defmodule Stein.Filter do
  @moduledoc """
  Filter an `Ecto.Query` by a map of parameters.

  ### Example Module

      defmodule MyApp.Orders do
        @behaviour Stein.Filter

        def filter_on_attribute({"name", value}, query) do
          value = "%" <> value <> "%"
          where(query, [o], like(o.name, ^value))
        end

        def filter_on_attribute(_, query), do: query
      end
  """

  @type attribute() :: String.t()

  @type callback_module() :: atom()

  @type pair() :: {attribute(), value()}

  @type params() :: %{attribute() => value()}

  @type query() :: Ecto.Query.t()

  @type value() :: String.t()

  @doc """
  This will be reduced from the query params that are passed into `filter/3`
  """
  @callback filter_on_attribute(pair(), query()) :: query()

  @doc """
  Filter a query based on a set of params

  This will reduce the query over the filter parameters.
  """
  @spec filter(query(), params(), callback_module()) :: query()
  def filter(query, nil, _), do: query

  def filter(query, filter, module) do
    filter
    |> Enum.reject(&(elem(&1, 1) == ""))
    |> Enum.reduce(query, &module.filter_on_attribute/2)
  end
end
