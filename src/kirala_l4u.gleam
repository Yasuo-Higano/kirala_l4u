//import score/score.{main as do_repl}
import l4u/l4u_core.{type Expr}
import l4u/l4u.{main as do_repl}

//import l4u/l4u_core.{main as do_repl}
//import l4u.{main as do_repl}

pub fn main() {
  do_repl()
}

pub fn start_with_defs(defs: List(#(String, Expr))) {
  l4u.start_with_defs(defs)
}
