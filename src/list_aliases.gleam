import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import list_aliases/alias.{type Alias}
import simplifile

pub fn main() {
  let aliases = {
    use zshrc_path <- result.try(get_zshrc_path())
    use file_content <- result.map(read_file_content(zshrc_path))

    file_content
    |> string.split("\n")
    |> list.filter(string.starts_with(_, "alias"))
    |> list.map(alias.from_string)
    |> result.partition
  }

  case aliases {
    Ok(#(valid_aliases, error_aliases)) -> {
      valid_aliases |> format_alias_list |> list.each(io.println)
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

fn format_alias_list(aliases: List(Alias)) -> List(String) {
  let max_name_length =
    aliases
    |> list.map(fn(x) { string.length(x.name) })
    |> list.max(int.compare)
    |> result.replace_error(0)
    |> result.unwrap_both

  list.map(aliases, alias.to_display_string(_, max_name_length))
}
