import gleam/string
import gleam_community/ansi

pub type Alias {
  Alias(name: String, command: String)
}

pub fn from_string(string: String) -> Result(Alias, String) {
  let prefix = "alias "
  case
    string.drop_start(string, string.length(prefix))
    |> string.split_once("=")
  {
    Ok(#(name, command)) ->
      Ok(Alias(name, command |> string.drop_end(1) |> string.drop_start(1)))
    _ -> Error(string)
  }
}

pub fn to_display_string(alias: Alias, padding_width: Int) -> String {
  Alias(..alias, name: string.pad_end(alias.name, padding_width, " "))
  |> format_alias_with_color
}

fn format_alias_with_color(alias: Alias) -> String {
  ansi.green(alias.name) <> ": " <> ansi.blue(alias.command)
}
