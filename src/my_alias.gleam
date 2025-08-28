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
    |> read_zshrc
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

fn read_zshrc(path: String) {
  case simplifile.read(path) {
    Ok(content) -> content
    Error(e) -> {
      let error = "Error reading .zshrc file: " <> simplifile.describe_error(e)
      panic as error
    }
  }
}

type AliasPair {
  AliasPair(alias: String, command: String)
}

fn format_alias_list(aliases: List(String)) -> #(List(String), List(String)) {
  let pairs = list.map(aliases, extract_pair)

  let #(valid_pairs, error_pairs) = result.partition(pairs)

  let assert Ok(larger_name) =
    valid_pairs
    |> list.map(fn(x) { string.length(x.alias) })
    |> list.max(int.compare)

  let formatted_alias = valid_pairs |> list.map(format_alias(_, larger_name))

  #(formatted_alias, error_pairs)
}

fn format_alias(pair: AliasPair, minimal_size: Int) -> String {
  pair
  |> fn(x) { AliasPair(..x, alias: string.pad_end(x.alias, minimal_size, " ")) }
  |> colored_output
}

fn extract_pair(line: String) -> Result(AliasPair, String) {
  let prefix = "alias "
  case
    string.drop_start(line, string.length(prefix)) |> string.split_once("=")
  {
    Ok(#(name, command)) -> Ok(AliasPair(name, drop_both(command)))
    _ -> Error(line)
  }
}

fn drop_both(input: String) -> String {
  input
  |> string.drop_start(1)
  |> string.drop_end(1)
}

fn colored_output(pair: AliasPair) -> String {
  ansi.green(pair.alias) <> ": " <> ansi.blue(pair.command)
}
