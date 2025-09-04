import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/ansi
import list_aliases/alias
import simplifile

pub fn main() {
  let #(valid_aliases, error_aliases) =
    get_zshrc_path()
    |> read_file_content
    |> string.split("\n")
    |> list.filter(string.starts_with(_, "alias"))
    |> format_alias_list

  valid_aliases |> list.each(io.println)

  io.println("")
  use error_alias <- list.each(error_aliases)
  io.println_error(ansi.red("Invalid alias: ") <> error_alias)
}

fn get_zshrc_path() {
  case envoy.get("HOME") {
    Ok(home) -> home <> "/.zshrc"
    Error(_) -> panic as "Cannot read HOME variable"
  }
}

fn read_file_content(path: String) {
  case simplifile.read(path) {
    Ok(content) -> content
    Error(e) -> {
      let error = "Error reading .zshrc file: " <> simplifile.describe_error(e)
      panic as error
    }
  }
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
