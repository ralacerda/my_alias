import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/ansi
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

type Alias {
  Alias(name: String, command: String)
}

fn format_alias_list(aliases: List(String)) -> #(List(String), List(String)) {
  let parsed_aliases = list.map(aliases, parse_alias)

  let #(valid_aliases, error_aliases) = result.partition(parsed_aliases)

  let assert Ok(max_name_length) =
    valid_aliases
    |> list.map(fn(x) { string.length(x.name) })
    |> list.max(int.compare)

  let formatted_aliases =
    valid_aliases |> list.map(format_alias(_, max_name_length))

  #(formatted_aliases, error_aliases)
}

fn format_alias(alias: Alias, padding_width: Int) -> String {
  Alias(..alias, name: string.pad_end(alias.name, padding_width, " "))
  |> format_alias_with_color
}

fn parse_alias(line: String) -> Result(Alias, String) {
  let prefix = "alias "
  case
    string.drop_start(line, string.length(prefix)) |> string.split_once("=")
  {
    Ok(#(name, command)) -> Ok(Alias(name, drop_both(command)))
    _ -> Error(line)
  }
}

fn drop_both(input: String) -> String {
  input
  |> string.drop_start(1)
  |> string.drop_end(1)
}

fn format_alias_with_color(alias: Alias) -> String {
  ansi.green(alias.name) <> ": " <> ansi.blue(alias.command)
}
