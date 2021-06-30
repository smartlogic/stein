defmodule Stein.Pagination do
  @moduledoc """
  Paginate an Ecto query

  Example:

      iex> Stein.Pagination.paginate(Repo, query, %{page: 1, per: 10})
      %{
        page: [...],
        pagination: %Stein.Pagination.Meta{
          current: 1,
          total: 2,
          total_count: 12,
          empty?: false
        }
      }
  """

  defstruct page: [], pagination: %{}

  defmodule Meta do
    @moduledoc """
    Metadata information about the pagination
    """

    @type t() :: %__MODULE__{
            current: integer(),
            total: integer(),
            total_count: integer(),
            empty?: boolean()
          }

    defstruct [:current, :total, :total_count, :empty?]
  end

  import Ecto.Query

  alias __MODULE__.Meta

  @type t :: %__MODULE__{}

  @type params() :: map()

  @type query() :: Ecto.Query.t()

  @doc """
  Paginate a query

  Returns the current and total pages
  """
  @spec paginate(Stein.repo(), query(), params()) :: t()
  def paginate(repo, query, %{page: page, per: per}) do
    offset = (page - 1) * per

    count =
      query
      |> exclude(:select)
      |> select([u], count(u))
      |> exclude(:order_by)
      |> exclude(:preload)
      |> exclude(:group_by)
      |> repo.one()
      |> ensure_number()

    total_pages = round(Float.ceil(count / per))

    query =
      query
      |> limit(^per)
      |> offset(^offset)
      |> repo.all()

    %__MODULE__{
      page: query,
      pagination: %Meta{
        current: page,
        total: total_pages,
        total_count: count,
        empty?: total_pages == 0
      }
    }
  end

  def paginate(repo, query, _) do
    query = repo.all(query)

    %__MODULE__{
      page: query,
      pagination: %Meta{
        current: 1,
        total: 1,
        total_count: Enum.count(query),
        empty?: Enum.empty?(query)
      }
    }
  end

  defp ensure_number(nil), do: 0
  defp ensure_number(count) when is_integer(count), do: count
end
