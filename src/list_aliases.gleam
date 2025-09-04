import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import list_aliases/alias
import simplifile

pub fn main() {
  let aliases = {
    use zshrc_path <- result.try(get_zshrc_path())
    use file_content <- result.map(read_file_content(zshrc_path))

    file_content
    |> string.split("\n")
    |> list.filter(string.starts_with(_, "alias"))
    // TODO: Partition should not be done inside format_alias_list
    |> format_alias_list
  }

  case aliases {
    Ok(#(formatted_aliases, error_aliases)) -> {
      list.each(formatted_aliases, io.println)
      list.each(error_aliases, fn(e) {
        io.println_error("Error parsing: " <> e)
      })
    }
    Error(e) -> io.println_error(e)
  }
}

fn get_zshrc_path() -> Result(String, String) {
  case envoy.get("HOME") {
    Ok(home) -> Ok(home <> "/.zshrc")
    Error(_) -> Error("Cannot read HOME variable")
  }
}

fn read_file_content(path: String) -> Result(String, String) {
  result.map_error(simplifile.read(path), fn(e) {
    "Error reading .zshrc file: " <> simplifile.describe_error(e)
  })
}

fn format_alias_list(lines: List(String)) -> #(List(String), List(String)) {
  let parsed_aliases = list.map(lines, alias.from_string)

  let #(valid_aliases, error_aliases) = result.partition(parsed_aliases)

  let assert Ok(max_name_length) =
    valid_aliases
    |> list.map(fn(x) { string.length(x.name) })
    |> list.max(int.compare)

  let formatted_aliases =
    valid_aliases |> list.map(alias.to_display_string(_, max_name_length))

  #(formatted_aliases, error_aliases)
}
