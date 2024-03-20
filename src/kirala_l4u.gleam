//import score/score.{main as do_repl}
import l4u/l4u_type.{type Expr}
import l4u/l4u_obj.{type L4uObj}
import l4u/l4u.{
  l4u_rep_native, l4u_rep_str, main as do_repl,
  start_and_generate_main_l4u as generate_main_l4u,
}

//import l4u/l4u_core.{main as do_repl}

//import l4u.{main as do_repl}

pub fn main() {
  do_repl()
}

//pub fn start_with_defs(defs: List(#(String, Expr))) {
//  l4u.start_with_defs(defs)
//}

pub fn start_and_generate_main_l4u(
  additional_defs: List(#(String, Expr)),
) -> L4uObj {
  generate_main_l4u(additional_defs)
}

pub fn start_main_l4u() -> L4uObj {
  generate_main_l4u([])
}

pub fn l4u_eval_to_str(l4uobj: L4uObj, src: String) -> String {
  l4u_rep_str(src, l4uobj)
}

pub fn l4u_eval_to_native(l4uobj: L4uObj, src: String) -> any {
  l4u_rep_native(src, l4uobj)
}
