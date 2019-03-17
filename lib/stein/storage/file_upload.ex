defmodule Stein.Storage.FileUpload do
  @moduledoc """
  Processed file struct for use in uploading.

  Create with `Stein.Storage.prep_file/1`
  """

  @type t() :: %__MODULE__{
          filename: String.t(),
          extension: String.t(),
          path: String.t()
        }

  defstruct [:filename, :extension, :path]
end
