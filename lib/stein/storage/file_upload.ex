defmodule Stein.Storage.FileUpload do
  @moduledoc """
  Struct for uploading files
  """

  @type t() :: %__MODULE__{
          filename: String.t(),
          path: String.t()
        }

  defstruct [:filename, :path]
end
