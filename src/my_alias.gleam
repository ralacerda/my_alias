import envoy
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/ansi
import simplifile

pub fn main() {
  get_zshrc_path()
  |> read_zshrc
  |> string.split("\n")
  |> list.filter(fn(x) { string.starts_with(x, "alias") })
  |> list.map(format_alias)
  |> string.join("\n")
  |> io.println
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

fn format_alias(line: String) -> String {
  line
  |> extract_pair()
  |> result.map(colored_output)
  |> result.map_error(fn(x) { "Problem with alias: " <> x })
  |> result.unwrap_both
}

fn extract_pair(line: String) -> Result(AliasPair, String) {
  let prefix = "alias "
  case
    string.drop_start(line, string.length(prefix)) |> string.split_once("=")
  {
    Ok(#(name, command)) -> {
      Ok(AliasPair(name, drop_both(command)))
    }
    _ -> {
      Error(line)
    }
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
