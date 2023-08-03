defmodule Image.DebugTest do
  use ExUnit.Case, async: true

  import Image.TestSupport

  test "debug" do
    path = image_path("test_1.PNG")

    # 1
    thumbor_path = %{
      hmac: "7Ib4AeQw0L0GskujEsGyPCEBSlc=",
      meta: false,
      trim: nil,
      crop: nil,
      fit: {:fit, []},
      size: {500, 900},
      horizontal_align: nil,
      vertical_align: nil,
      smart: false,
      filters: [],
      source: "https://example.com/test_1.PNG"
    }

    {:ok, image} = Image.from_binary(File.read!(path))
    {width, height, _} = Image.shape(image)

    crop =
      if width <= height do
        case thumbor_path.vertical_align || :middle do
          :top -> :high
          :middle -> :center
          :bottom -> :low
        end
      else
        case thumbor_path.horizontal_align || :center do
          :left -> :high
          :center -> :center
          :right -> :low
        end
      end

    opts =
      case thumbor_path.fit do
        :default -> [crop: crop]
        {:fit, _} -> [crop: :none, resize: :both]
      end

    dbg(tumb: opts)

    image =
      Enum.reduce(thumbor_path, image, fn
        {:size, {a, b}}, image ->
          Image.thumbnail!(
            image,
            size_and_dimensions_to_thumbnail({a, b}, {width, height}),
            opts
          )

        _, image ->
          image
      end)

    opts =
      thumbor_path.source
      |> URI.new!()
      |> Map.get(:path)
      |> Path.extname()
      |> String.downcase()
      |> case do
        ".jpg" -> [suffix: ".jpg", progressive: true, quality: 100]
        ".png" -> [suffix: ".png", progressive: true]
        suffix -> [suffix: suffix]
      end

    dbg(stream: opts)

    # conn = send_chunked(conn, 200)
    file =
      image
      |> Image.stream!(opts ++ [buffer_size: 5_242_880])
      |> Enum.into(<<>>)
  end

  defp size_and_dimensions_to_thumbnail({0, b}, {w, h}) do
    a = trunc(w / h * b)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, 0}, {w, h}) do
    b = trunc(h / w * a)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, b}, _), do: "#{a}x#{b}"
end
