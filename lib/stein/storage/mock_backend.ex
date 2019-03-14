defmodule Stein.Storage.MockBackend do
  @moduledoc """
  A no-op storage backend for testing
  """

  @behaviour Stein.Storage

  @impl true
  def delete(_key), do: :ok

  @impl true
  def download(key) do
    {:ok, key}
  end

  @impl true
  def upload(_file, _key, _opts), do: :ok

  @impl true
  def url(key, _opts), do: key
end
