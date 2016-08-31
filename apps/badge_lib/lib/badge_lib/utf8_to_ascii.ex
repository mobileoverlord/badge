defmodule BadgeLib.Utf8ToASCII do
  def convert(string), do: convert(string, <<>>)

  def convert(<<c::utf8, rest::binary>>, result) when c <= 127 do
    convert(rest, result <> <<c::utf8>>)
  end
  def convert(<<_::utf8, rest::binary>>, result) do
    convert(rest, result)
  end
  def convert(<<>>, result) do
    result
  end
end
