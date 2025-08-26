import envoy
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  get_zshrc_path()
  |> read_zshrc
  |> string.split("\n")
  |> list.filter(fn(x) { string.starts_with(x, "alias") })
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

fn extract_pair(line: String) -> Result(AliasPair, Nil) {
  let prefix = "alias "
  case string.drop_start(line, string.length(prefix)) |> string.split("=") {
    [name, command] -> {
      Ok(AliasPair(name, drop_both(command)))
    }
    _ -> Error(Nil)
  }
}

fn drop_both(input: String) -> String {
  input
  |> string.drop_start(1)
  |> string.drop_end(1)
}
