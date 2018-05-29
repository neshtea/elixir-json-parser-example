defmodule FP.Parser do
  @moduledoc """
  This module implements a JSON parser.
  The principal function, `parse`, takes a JSON-String and returns the parsed
  struct (in terms of `FP.JSON.*` structs).
  """

  def parse!(string) do
    {result, _} = skip_white(string) |> parse()
    result
  end

  def parse(""), do: {nil, ""}

  def parse("null" <> rest), do: {nil, rest}

  def parse("true" <> rest), do: {true, rest}

  def parse("false" <> rest), do: {false, rest}

  def parse(<<char, _ :: binary>> = string) when char in '-0123456789' do
    parse_number(string)
  end

  # String
  def parse("\"" <> rest), do: parse_string(rest)

  # Object
  def parse("{" <> rest), do: skip_white(rest) |> parse_object([])

  # Array
  def parse("[" <> rest), do: skip_white(rest) |> parse_array([])

  # Number helper
  defp parse_number("-" <> rest) do
    case rest do
      "0" <> rest -> parse_frac(rest, ["-0"])
      rest -> parse_int(rest, [?-])
    end
  end

  defp parse_number("0" <> rest), do: parse_frac(rest, [?0])

  defp parse_number(string), do: parse_int(string, [])

  defp parse_int(<<char, _ :: binary>> = string, acc) when char in '123456789' do
    {digits, rest} = parse_digits(string)
    parse_frac(rest, [acc, digits])
  end

  defp parse_frac("." <> rest, acc) do
    {digits, rest} = parse_digits(rest)
    parse_exp(rest, true, [acc, ?., digits])
  end

  defp parse_frac(string, acc), do: parse_exp(string, false, acc)

  defp parse_exp(<<e>> <> rest, frac, acc) when e in 'eE' do
    e = if frac, do: ?e, else: ".0e"
    case rest do
      "-" <> rest -> parse_exp_rest(rest, frac, [acc, e, ?-])
      "+" <> rest -> parse_exp_rest(rest, frac, [acc, e])
      rest -> parse_exp_rest(rest, frac, [acc, e])
    end
  end

  defp parse_exp(string, frac, acc), do: {parse_number_complete(acc, frac), string}

  defp parse_exp_rest(rest, _, acc) do
    {digits, rest} = parse_digits(rest)
    {parse_number_complete([acc, digits], true), rest}
  end

  defp parse_number_complete(iolist, false) do
    IO.iodata_to_binary(iolist) |> String.to_integer
  end

  defp parse_number_complete(iolist, true) do
    IO.iodata_to_binary(iolist) |> String.to_float
  end

  defp parse_digits(<<char>> <> rest = string) when char in '0123456789' do
    count = count_digits(rest, 1)
    <<digits :: binary-size(count), rest :: binary>> = string
    {digits, rest}
  end

  defp count_digits(<<char>> <> rest, acc) when char in '0123456789' do
    count_digits(rest, acc + 1)
  end

  defp count_digits(_, acc), do: acc

  # Object helper
  defp parse_object("}" <> rest, acc), do: {Map.new(acc), rest}
  defp parse_object("," <> rest, acc), do: skip_white(rest) |> parse_object(acc)
  defp parse_object("\"" <> rest, acc) do
    {name, rest} = parse_string(rest)  # Parse the name (key)
    ":" <> rest = skip_white(rest)
    {value, rest} = skip_white(rest) |> parse()  # Parse the value
    acc = [{name, value} | acc]
    parse_object(rest, acc)
  end

  # Array helper
  defp parse_array("]" <> rest, acc), do: {Enum.reverse(acc), rest}
  defp parse_array("," <> rest, acc), do: parse_array(rest, acc)
  defp parse_array(string, acc) do
    {value, rest} = skip_white(string) |> parse()
    skip_white(rest) |> parse_array([value | acc])
  end

  ## String helper
  def parse_string(x), do: parse_string(x, [])
  def parse_string("\"" <> rest, acc) do
    {IO.iodata_to_binary(acc), rest}
  end
  def parse_string(string, acc) do
    count = string_chunk_size(string, 0)
    <<chunk :: binary-size(count), res :: binary>> = string
    parse_string(res, [acc, chunk])
  end

  defp string_chunk_size("\"" <> _, acc), do: acc
  defp string_chunk_size("\\" <> _, acc), do: acc

  defp string_chunk_size(<<char>> <> rest, acc) when char < 0x80 do
    string_chunk_size(rest, acc + 1)
  end

  defp string_chunk_size(<<codepoint :: utf8>> <> rest, acc) do
    string_chunk_size(rest, acc + string_codepoint_size(codepoint))
  end

  defp string_codepoint_size(codepoint) when codepoint < 0x800,   do: 2
  defp string_codepoint_size(codepoint) when codepoint < 0x10000, do: 3
  defp string_codepoint_size(_),                                  do: 4

  # Whitespace
  defp skip_white(<<char>> <> rest) when char in '\s\n\t\r' do
    skip_white(rest)
  end
  defp skip_white(string), do: string

end
