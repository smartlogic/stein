defmodule Stein.Storage do
  @moduledoc """
  Handle storing files in the cloud or local file system
  """

  alias Stein.Storage.FileBackend
  alias Stein.Storage.FileUpload
  alias Stein.Storage.MockBackend
  alias Stein.Storage.S3Backend

  @type file :: FileUpload.t()

  @type key :: String.t()

  @type map_file :: %{path: String.t()}

  @type opts :: Keyword.t()

  @type path :: Path.t()

  @type url :: String.t()

  @callback delete(key()) :: :ok

  @callback download(key()) :: {:ok, path()}

  @callback upload(file(), key()) :: :ok | :error

  @callback url(key()) :: url()

  @doc """
  Delete files from remote storage
  """
  @spec delete(key()) :: :ok
  def delete(key) do
    backend().delete(key)
  end

  @doc """
  Download files from remote storage

  *Note*: this creates a temporary file and must be cleaned up manually
  """
  @spec download(key()) :: {:ok, path()}
  def download(key) do
    backend().download(key)
  end

  @doc """
  Upload files to the remote storage
  """
  @spec upload(file(), key(), opts()) :: :ok | {:error, :check_extensions} | {:error, :uploading}
  def upload(file, key, opts) do
    path = prep_file(file)

    with {:ok, :extension} <- check_extensions(path, opts) do
      backend().upload(path, key)
    end
  end

  defp check_extensions(file, opts) do
    allowed_extensions = Keyword.get(opts, :extensions, [])
    extension = String.downcase(Path.extname(file.filename))

    case extension in allowed_extensions do
      true ->
        {:ok, :extension}

      false ->
        {:error, :invalid_extension}
    end
  end

  @doc """
  Get the remote url for viewing an uploaded file
  """
  @spec url(key()) :: url()
  def url(key) do
    backend().url(key)
  end

  @doc """
  Prepare a file for upload to the backend

  Must be a `Stein.Storage.FileUpload`, `Plug.Upload`, or a map that
  has the `:path` key.
  """
  @spec prep_file(file()) :: file()

  @spec prep_file(Plug.Upload.t()) :: file()

  @spec prep_file(map_file()) :: file()

  def prep_file(upload = %FileUpload{}), do: upload

  def prep_file(upload = %Plug.Upload{}) do
    %FileUpload{filename: upload.filename, path: upload.path}
  end

  def prep_file(upload) when is_map(upload) do
    %FileUpload{filename: Path.basename(upload.path), path: upload.path}
  end

  @doc false
  def backend() do
    case Application.get_env(:stein, :storage)[:backend] do
      :file ->
        FileBackend

      :s3 ->
        S3Backend

      :test ->
        MockBackend
    end
  end
end
