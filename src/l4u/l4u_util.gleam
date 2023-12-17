import gleam/string
import gleam/result
import gleam/list

// split String to List(String)
// split string to """"multi line string"""" and others
pub fn split_multiline_string(src: String) -> List(String) {
  split_multiline_rec(src, [])
}

fn split_multiline_rec(src: String, acc: List(String)) -> List(String) {
  case src {
    "" -> list.reverse(acc)
    "\"\"\"" <> r1 -> {
      let #(mlstr, rest) = read_multiline_string(r1, "\"\"\"")
      split_multiline_rec(rest, [mlstr, ..acc])
    }
    _ -> {
      let #(str, rest) = read_until_multiline_string(src, "")
      split_multiline_rec(rest, [str, ..acc])
    }
  }
}

fn read_multiline_string(src: String, acc: String) -> #(String, String) {
  case src {
    "" -> #(acc, "")
    "\"\"\"" <> rest -> #(acc <> "\"\"\"", rest)
    _ -> {
      let #(char, rest) =
        string.pop_grapheme(src)
        |> result.unwrap(#("", ""))

      read_multiline_string(rest, acc <> char)
    }
  }
}

fn read_until_multiline_string(src: String, acc: String) -> #(String, String) {
  case src {
    "" -> #(acc, "")
    "\"\"\"" <> _ -> #(acc, src)
    _ -> {
      let #(char, rest) =
        string.pop_grapheme(src)
        |> result.unwrap(#("", ""))

      read_until_multiline_string(rest, acc <> char)
    }
  }
}
