defmodule Stein.Storage do
  @moduledoc """
  Handle storing files in the cloud or local file system
  """

  alias Stein.Storage.FileBackend
  alias Stein.Storage.FileUpload
  alias Stein.Storage.MockBackend
  alias Stein.Storage.S3Backend

  @type file :: FileUpload.t()

  @typedoc """
  Key for where the document will be stored

  Must start with a leading `/`
  """
  @type key :: String.t()

  @type map_file :: %{path: String.t()}

  @type opts :: Keyword.t()

  @type path :: Path.t()

  @type url :: String.t()

  @callback delete(key()) :: :ok

  @callback download(key()) :: {:ok, path()}

  @callback upload(file(), key(), opts()) :: :ok | :error

  @callback url(key(), opts()) :: url()

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
      backend().upload(path, key, opts)
    end
  end

  @doc false
  def check_extensions(file, opts) do
    allowed_extensions = Keyword.get(opts, :extensions)
    check_allowed_extensions(file, allowed_extensions)
  end

  defp check_allowed_extensions(_file, nil), do: {:ok, :extension}

  defp check_allowed_extensions(file, allowed_extensions) do
    extension = String.downcase(file.extension)

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
  @spec url(key(), opts()) :: url()
  def url(key, opts \\ []) do
    backend().url(key, opts)
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
    %FileUpload{
      filename: upload.filename,
      extension: Path.extname(upload.filename),
      path: upload.path
    }
  end

  def prep_file(upload) when is_map(upload) do
    filename = Path.basename(upload.path)

    %FileUpload{
      filename: Path.basename(upload.path),
      extension: Path.extname(filename),
      path: upload.path
    }
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
