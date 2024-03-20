// npm install mustache --save
import gleam/dict
import gleam/dynamic
@target(erlang)
import gleam/bbmustache

@target(erlang)
pub type Argument =
  bbmustache.Argument

@target(erlang)
pub type MustacheTemplate =
  bbmustache.Template

@target(javascript)
pub type MustacheTemplate =
  String

@target(javascript)
pub type Argument =
  String

@target(erlang)
pub fn string(arg: String) -> Argument {
  bbmustache.string(arg)
}

@target(javascript)
pub fn string(arg: String) -> Argument {
  arg
}

// --------------------------------------------------------------------
// javascript
// --------------------------------------------------------------------
@target(javascript)
pub fn compile(src: String) -> MustacheTemplate {
  src
}

@target(javascript)
@external(javascript, "../bbmustache_ffi.mjs", "render")
fn render_(
  template: MustacheTemplate,
  table: List(#(String, Argument)),
) -> MustacheTemplate

@target(javascript)
pub fn render(
  template: MustacheTemplate,
  table: List(#(String, String)),
) -> String {
  render_(template, table)
}

// --------------------------------------------------------------------
// erlang
// --------------------------------------------------------------------
@target(erlang)
pub fn compile(src: String) -> MustacheTemplate {
  let assert Ok(template) = bbmustache.compile(src)
  template
}

@target(erlang)
pub fn render(
  template: MustacheTemplate,
  table: List(#(String, Argument)),
) -> String {
  bbmustache.render(template, table)
}
