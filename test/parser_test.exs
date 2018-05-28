defmodule FP.ParserTest do
  use ExUnit.Case

  alias FP.Parser

  test "empty string returns nil" do
    assert nil == Parser.parse!("")
  end

  test "parsing a null returns nil" do
    assert nil == Parser.parse!("null")
  end

  test "parsing a number returns the correct number" do
    assert 42 == Parser.parse!("42")
    assert -23 == Parser.parse!("-23")

    assert 42.0 == Parser.parse!("42.0")
    assert 23.42 == Parser.parse!("23.42")

    assert 3.7e-5 == Parser.parse!("3.7e-5")
    assert 3.7e-5 == Parser.parse!("3.7E-5")


  end

  test "parsing a boolean returns the correct boolean" do
    assert true == Parser.parse!("true")
    assert false == Parser.parse!("false")
  end

  test "parsing an array returns the corresponding list" do
    assert [1,2,3] == Parser.parse!("[1,2,3]")
    assert [42, true, "foobar"] == Parser.parse!("[42, true, \"foobar\"]")

    # Nested array.
    assert [42, true, [42, true]] == Parser.parse!("[42, true, [42, true]]")
  end

  test "parsing an object returns the corresponding elixir map" do
    assert %{} == Parser.parse!("{}")
    assert %{"foo" => 42} == Parser.parse!("{\"foo\": 42}")

    complex_json = Parser.parse!("{\"foo\": 42, \"bar\": true, \"fizz\": 3.7e-5, \"buzz\": [42, true, [\"done\"]]}")
    assert %{"foo" => 42,
             "bar" => true,
             "fizz" => 3.7e-5,
             "buzz" => [42, true, ["done"]]} == complex_json
  end

  test "whitespace doesn't matter" do
    assert 42 == Parser.parse!("            42            ")
    assert [1, 2, 3] == Parser.parse!("  [         1,     2, 3      ] ")
  end

end
