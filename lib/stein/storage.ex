defmodule Stein.Storage do
  @moduledoc """
  `Stein.Storage` covers uploading, downloading, and deleting remote files

  ## Available backends

  ### FileBackend

  The `Stein.Storage.FileBackend` is available for development purposes.

  For the file backend, you can configure the folder Stein should use. This
  should be a local folder that Elixir has read/write permissions to. It should
  end with a trailing slash.

      config :stein, :storage,
        backend: :file,
        file_backend_folder: "uploads/"

  The default folder is Stein's `priv/files`.

  To fully support the file storage, you should also add a new `Plug.Static`
  to your endpoint. This will let the URLs the backend returns load.

       if Mix.env() == :dev do
         plug(Plug.Static, at: "/uploads", from: "uploads/files")
       end

  ### S3Backend

  The `Stein.Storage.S3Backend` handles uploading, downloading, and deletes
  from Amazon S3.

  For the S3 backend, you can also configure the bucket Stein should upload to.

      config :stein, :storage,
        backend: :s3,
        bucket: "my-bucket"

  ### MockBackend

  The `Stein.Storage.MockBackend` mocks out all actions for use in tests. Each
  action is a no-op.

      config :stein, :storage,
        backend: :test
  """

  alias Stein.Storage.FileBackend
  alias Stein.Storage.FileUpload
  alias Stein.Storage.MockBackend
  alias Stein.Storage.S3Backend

  @typedoc """
  A processed file ready for uploading
  """
  @type file :: FileUpload.t()

  @typedoc """
  Key for where the document will be stored

  Must start with a leading `/`
  """
  @type key :: String.t()

  @typedoc """
  Options for a function
  """
  @type opts :: Keyword.t()

  @typedoc """
  A local file path
  """
  @type local_path :: Path.t()

  @typedoc """
  The URL for viewing the remote file
  """
  @type url :: String.t()

  @doc """
  Delete files from remote storage
  """
  @callback delete(key()) :: :ok

  @doc """
  Download files from remote storage

  *Note*: this creates a temporary file and must be cleaned up manually
  """
  @callback download(key()) :: {:ok, local_path()}

  @doc """
  Upload files to the remote storage
  """
  @callback upload(file(), key(), opts()) :: :ok | :error

  @doc """
  Get the remote url for viewing an uploaded file
  """
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
  @spec download(key()) :: {:ok, local_path()}
  def download(key) do
    backend().download(key)
  end

  @doc """
  Upload files to the remote storage

  ## Limiting extensions

  You can limit extensions with the `extensions` option. Only the extensions in the list
  will be allowed, any other extension will be rejected with `{:error, :invalid_extension}`.

  Each extension should start with a `.`.

      Stien.Storage.upload(file, key, extensions: [".jpg", ".png"])

  """
  @spec upload(file(), key(), opts()) :: :ok | {:error, :invalid_extension} | {:error, :uploading}
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

  @spec prep_file(%{path: String.t()}) :: file()

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
