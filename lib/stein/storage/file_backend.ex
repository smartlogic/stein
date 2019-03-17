defmodule Stein.Storage.FileBackend do
  @moduledoc """
  Backend for using local file storage.

  See `Stein.Storage` for more information about configuration available.
  """

  alias Stein.Storage.Temp

  @behaviour Stein.Storage

  @doc false
  def local_folder() do
    config = Application.get_env(:stein, :storage, [])
    Keyword.get(config, :file_backend_folder) || :code.priv_dir(:stein)
  end

  @impl true
  def delete(key) do
    path = Path.join(local_folder(), "files/#{key}")
    File.rm(path)

    :ok
  end

  @impl true
  def download(key) do
    path = Path.join(local_folder(), "files/#{key}")
    extname = Path.extname(path)
    {:ok, temp_path} = Temp.create(extname: extname)
    File.copy(path, temp_path)
    {:ok, temp_path}
  end

  @impl true
  def upload(file, key, _opts) do
    path = Path.join(local_folder(), "files/#{key}")

    dirname = Path.dirname(path)
    File.mkdir_p(dirname)

    case File.copy(file.path, path) do
      {:ok, _} ->
        :ok

      _ ->
        {:error, :uploading}
    end
  end

  @impl true
  def url("/" <> key, opts), do: url(key, opts)

  def url(key, _opts) do
    "/uploads/#{key}"
  end
end
