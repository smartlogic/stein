defmodule Stein.Storage.Temp do
  @moduledoc """
  Temporary file helper
  """

  @tmp_dir "/tmp/stein"

  @doc """
  Create a new temporary file
  """
  def create(opts) do
    File.mkdir_p(@tmp_dir)

    filename =
      [timestamp(), opts[:extname]]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("")

    path = Path.join([@tmp_dir, filename])

    File.touch(path)

    {:ok, path}
  end

  defp timestamp(), do: to_string(:os.system_time())
end
