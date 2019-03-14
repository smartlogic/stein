defmodule Stein.StorageTest do
  use ExUnit.Case

  alias Stein.Storage

  describe "checking file extensions" do
    test "extension is allowed" do
      file = %Storage.FileUpload{extension: ".jpg"}
      {:ok, :extension} = Storage.check_extensions(file, extensions: [".jpg"])
    end

    test "extension is not allowed" do
      file = %Storage.FileUpload{extension: ".png"}
      {:error, :invalid_extension} = Storage.check_extensions(file, extensions: [".jpg"])
    end

    test "skip extension checks" do
      file = %Storage.FileUpload{extension: ".jpg"}
      {:ok, :extension} = Storage.check_extensions(file, [])
    end
  end

  describe "preparing a file for upload" do
    test "a plain map" do
      file = Storage.prep_file(%{path: "/tmp/test.pdf"})

      assert file.filename == "test.pdf"
      assert file.extension == ".pdf"
      assert file.path == "/tmp/test.pdf"
    end

    test "plug upload" do
      file =
        Storage.prep_file(%Plug.Upload{
          path: "/tmp/test.pdf",
          filename: "test.pdf"
        })

      assert file.filename == "test.pdf"
      assert file.extension == ".pdf"
      assert file.path == "/tmp/test.pdf"
    end

    test "pass through" do
      file =
        Storage.prep_file(%Storage.FileUpload{
          path: "/tmp/test.pdf",
          extension: ".pdf",
          filename: "test.pdf"
        })

      assert file.filename == "test.pdf"
      assert file.extension == ".pdf"
      assert file.path == "/tmp/test.pdf"
    end
  end
end
