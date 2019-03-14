defmodule Stein.Storage.FileUpload do
  @moduledoc """
  Struct for uploading files
  """

  @type t() :: %__MODULE__{
          filename: String.t(),
          extension: String.t(),
          path: String.t()
        }

  defstruct [:filename, :extension, :path]
end
