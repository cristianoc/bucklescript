#2 "utils/config.mlp"
(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Xavier Leroy, projet Cristal, INRIA Rocquencourt           *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* The main OCaml version string has moved to ../VERSION *)
let version = "4.06.0+BS"

let standard_library_default = "/usr/local/lib/ocaml/lib/ocaml" (* does not matter *)

let standard_library =
    standard_library_default

let standard_runtime = "/usr/local/bin/ocaml/bin/ocamlrun"
let ccomp_type = "cc"
let c_compiler = "gcc"
let c_output_obj = "-o "
let ocamlc_cflags = "-O2 -fno-strict-aliasing -fwrapv "
let ocamlc_cppflags = "-D_FILE_OFFSET_BITS=64 -D_REENTRANT"
let ocamlopt_cflags = "-O2 -fno-strict-aliasing -fwrapv"
let ocamlopt_cppflags = "-D_FILE_OFFSET_BITS=64 -D_REENTRANT"
let bytecomp_c_libraries = "-lcurses -lpthread                  "
(* bytecomp_c_compiler and native_c_compiler have been supported for a
   long time and are retained for backwards compatibility.
   For programs that don't need compatibility with older OCaml releases
   the recommended approach is to use the constituent variables
   c_compiler, ocamlc_cflags, ocamlc_cppflags etc., directly.
*)
let bytecomp_c_compiler =
  c_compiler ^ " " ^ ocamlc_cflags ^ " " ^ ocamlc_cppflags
let native_c_compiler =
  c_compiler ^ " " ^ ocamlopt_cflags ^ " " ^ ocamlopt_cppflags
let native_c_libraries = ""
let native_pack_linker = "ld -r -arch x86_64 -o\ "
let ranlib = "ranlib"
let ar = "ar"
let cc_profile = "-pg"
let mkdll, mkexe, mkmaindll =
  (* @@DRA Cygwin - but only if shared libraries are enabled, which we
     should be able to detect? *)
  if Sys.os_type = "Win32" then
    try
      let flexlink =
        let flexlink = Sys.getenv "OCAML_FLEXLINK" in
        let f i =
          let c = flexlink.[i] in
          if c = '/' then '\\' else c in
        (String.init (String.length flexlink) f) ^ " " in
      flexlink,
      flexlink ^ " -exe",
      flexlink ^ " -maindll"
    with Not_found ->
      "gcc -shared -flat_namespace -undefined suppress                    -Wl,-no_compact_unwind", "gcc -O2 -fno-strict-aliasing -fwrapv -Wall -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DCAML_NAME_SPACE   -Wl,-no_compact_unwind", "gcc -shared -flat_namespace -undefined suppress                    -Wl,-no_compact_unwind"
  else
    "gcc -shared -flat_namespace -undefined suppress                    -Wl,-no_compact_unwind", "gcc -O2 -fno-strict-aliasing -fwrapv -Wall -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DCAML_NAME_SPACE   -Wl,-no_compact_unwind", "gcc -shared -flat_namespace -undefined suppress                    -Wl,-no_compact_unwind"

let profiling = true
let flambda = false
let safe_string = false
let default_safe_string = true
let windows_unicode = 0 != 0

let flat_float_array = true

let afl_instrument = false

let exec_magic_number = "Caml1999X011"
and cmi_magic_number = "Caml1999I022"
and cmo_magic_number = "Caml1999O022"
and cma_magic_number = "Caml1999A022"
and cmx_magic_number =
  if flambda then
    "Caml1999y022"
  else
    "Caml1999Y022"
and cmxa_magic_number =
  if flambda then
    "Caml1999z022"
  else
    "Caml1999Z022"
and ast_impl_magic_number = "Caml1999M022"
and ast_intf_magic_number = "Caml1999N022"
and cmxs_magic_number = "Caml1999D022"
    (* cmxs_magic_number is duplicated in otherlibs/dynlink/natdynlink.ml *)
and cmt_magic_number = "Caml1999T022"

let load_path = ref ([] : string list)

let interface_suffix = ref ".mli"

let max_tag = 245
(* This is normally the same as in obj.ml, but we have to define it
   separately because it can differ when we're in the middle of a
   bootstrapping phase. *)
let lazy_tag = 246

let max_young_wosize = 256
let stack_threshold = 256 (* see byterun/config.h *)
let stack_safety_margin = 60

let architecture = "amd64"
let model = "default"
let system = "macosx"

let asm = "clang -arch x86_64 -Wno-trigraphs -c"
let asm_cfi_supported = true
let with_frame_pointers = false
let spacetime = false
let enable_call_counts = true
let libunwind_available = false
let libunwind_link_flags = ""
let profinfo = false
let profinfo_width = 0

let ext_exe = ""
let ext_obj = ".o"
let ext_asm = ".s"
let ext_lib = ".a"
let ext_dll = ".so"

let host = "x86_64-apple-darwin16.7.0"
let target = "x86_64-apple-darwin16.7.0"

let default_executable_name =
  match Sys.os_type with
    "Unix" -> "a.out"
  | "Win32" | "Cygwin" -> "camlprog.exe"
  | _ -> "camlprog"

let systhread_supported = true;;

let flexdll_dirs = [];;

let print_config oc = ()
;;
