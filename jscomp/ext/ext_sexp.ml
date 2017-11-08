# 1 "ext/ext_sexp.mll"
 

type error =
  | Illegal_character of char
  | Illegal_escape of string
  | Unbalanced_paren 
  | Unterminated_paren
  | Unterminated_string
  | Non_sexp_outside
exception Error of error * Lexing.position * Lexing.position;;

let error  (lexbuf : Lexing.lexbuf) e = 
  raise (Error (e, lexbuf.lex_start_p, lexbuf.lex_curr_p))


let char_for_backslash = function
  | 'n' -> '\010'
  | 'r' -> '\013'
  | 'b' -> '\008'
  | 't' -> '\009'
  | c -> c

let lf = '\010'

let dec_code c1 c2 c3 =
  100 * (Char.code c1 - 48) + 10 * (Char.code c2 - 48) + (Char.code c3 - 48)

let hex_code c1 c2 =
  let d1 = Char.code c1 in
  let val1 =
    if d1 >= 97 then d1 - 87
    else if d1 >= 65 then d1 - 55
    else d1 - 48 in
  let d2 = Char.code c2 in
  let val2 =
    if d2 >= 97 then d2 - 87
    else if d2 >= 65 then d2 - 55
    else d2 - 48 in
  val1 * 16 + val2

let update_loc ({ lex_curr_p; _ } as lexbuf : Lexing.lexbuf) diff =
  lexbuf.lex_curr_p <-
    {
      lex_curr_p with
      pos_lnum = lex_curr_p.pos_lnum + 1;
      pos_bol = lex_curr_p.pos_cnum - diff;
    }

let lexeme_len ({ lex_start_pos; lex_curr_pos; _ } : Lexing.lexbuf) =
  lex_curr_pos - lex_start_pos



type t  =
  | Atom of string 
  | List of t list
  | Data of t list 
  | Lit of string 



type st = 
  { sexps : (t list * bool) Stack.t ; 
    mutable top : t list   ;
    mutable has_prime : bool ;
    buf : Buffer.t;
    mutable paren_depth : int
  }

let push_atom lexbuf atom (buf : st ) = 
  buf.top <- atom:: buf.top

(** entering the new stack *)
let new_lparen has_prime buf = 
  buf.paren_depth <- buf.paren_depth + 1 ;
  Stack.push (buf.top, buf.has_prime) buf.sexps ;
  buf.top <- [];
  buf.has_prime <- has_prime

(** exit the stack *)
let new_rparen  buf lexbuf = 
  buf.paren_depth <- buf.paren_depth - 1 ; 
  if buf.paren_depth < 0  then
    error lexbuf Unbalanced_paren
  else 
    let new_sexp =
      if buf.has_prime then 
        Data (List.rev   buf.top)
      else List (List.rev   buf.top) 
    in 
    let top, has_prime =  Stack.pop buf.sexps in
    buf.top<- top;
    buf.has_prime<-has_prime;
    push_atom lexbuf new_sexp buf 

let get_data buf = buf.top


# 101 "ext/ext_sexp.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\246\255\247\255\078\000\249\255\250\255\251\255\002\000\
    \001\000\006\000\006\000\255\255\252\255\191\000\246\255\192\000\
    \248\255\195\000\255\255\249\255\012\001\161\000\252\255\007\000\
    \011\000\012\000\210\000\251\255\035\001\250\255";
  Lexing.lex_backtrk =
   "\255\255\255\255\255\255\007\000\255\255\255\255\255\255\008\000\
    \002\000\001\000\008\000\255\255\255\255\255\255\255\255\008\000\
    \255\255\255\255\255\255\255\255\006\000\006\000\255\255\006\000\
    \001\000\002\000\255\255\255\255\255\255\255\255";
  Lexing.lex_default =
   "\002\000\000\000\000\000\255\255\000\000\000\000\000\000\255\255\
    \008\000\255\255\255\255\000\000\000\000\015\000\000\000\015\000\
    \000\000\019\000\000\000\000\000\255\255\255\255\000\000\255\255\
    \255\255\255\255\255\255\000\000\255\255\000\000";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\009\000\011\000\255\255\009\000\010\000\255\255\009\000\
    \011\000\025\000\009\000\000\000\024\000\025\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \009\000\000\000\004\000\000\000\000\000\000\000\009\000\007\000\
    \006\000\005\000\012\000\024\000\025\000\003\000\003\000\000\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\000\000\008\000\000\000\003\000\000\000\003\000\
    \000\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\000\000\000\000\000\000\000\000\003\000\
    \000\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\000\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \000\000\000\000\000\000\003\000\000\000\003\000\000\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\000\000\000\000\000\000\000\000\003\000\000\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\016\000\255\255\000\000\000\000\024\000\000\000\000\000\
    \023\000\026\000\026\000\026\000\026\000\026\000\026\000\026\000\
    \026\000\026\000\026\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\018\000\255\255\022\000\000\000\022\000\000\000\000\000\
    \000\000\000\000\022\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\021\000\021\000\021\000\021\000\021\000\
    \021\000\021\000\021\000\021\000\021\000\000\000\000\000\000\000\
    \001\000\255\255\027\000\027\000\027\000\027\000\027\000\027\000\
    \027\000\027\000\027\000\027\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\017\000\255\255\000\000\000\000\022\000\
    \000\000\000\000\000\000\000\000\000\000\022\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\022\000\000\000\000\000\000\000\022\000\000\000\022\000\
    \000\000\000\000\000\000\020\000\028\000\028\000\028\000\028\000\
    \028\000\028\000\028\000\028\000\028\000\028\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\028\000\028\000\028\000\
    \028\000\028\000\028\000\029\000\029\000\029\000\029\000\029\000\
    \029\000\029\000\029\000\029\000\029\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\029\000\029\000\029\000\029\000\
    \029\000\029\000\000\000\000\000\000\000\028\000\028\000\028\000\
    \028\000\028\000\028\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\029\000\029\000\029\000\029\000\
    \029\000\029\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\014\000\
    \255\255\000\000\000\000\255\255\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\008\000\000\000\000\000\008\000\009\000\
    \010\000\023\000\009\000\255\255\024\000\025\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\255\255\000\000\255\255\255\255\255\255\009\000\000\000\
    \000\000\000\000\007\000\024\000\025\000\000\000\000\000\255\255\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\255\255\000\000\255\255\000\000\255\255\000\000\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\255\255\255\255\255\255\000\000\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\003\000\003\000\255\255\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \255\255\255\255\255\255\003\000\255\255\003\000\255\255\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\255\255\255\255\255\255\255\255\003\000\255\255\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\013\000\015\000\255\255\255\255\017\000\255\255\255\255\
    \017\000\021\000\021\000\021\000\021\000\021\000\021\000\021\000\
    \021\000\021\000\021\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\013\000\015\000\017\000\255\255\017\000\255\255\255\255\
    \255\255\255\255\017\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\017\000\017\000\017\000\017\000\017\000\
    \017\000\017\000\017\000\017\000\017\000\255\255\255\255\255\255\
    \000\000\008\000\026\000\026\000\026\000\026\000\026\000\026\000\
    \026\000\026\000\026\000\026\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\013\000\015\000\255\255\255\255\017\000\
    \255\255\255\255\255\255\255\255\255\255\017\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\017\000\255\255\255\255\255\255\017\000\255\255\017\000\
    \255\255\255\255\255\255\017\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\020\000\020\000\020\000\
    \020\000\020\000\020\000\028\000\028\000\028\000\028\000\028\000\
    \028\000\028\000\028\000\028\000\028\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\028\000\028\000\028\000\028\000\
    \028\000\028\000\255\255\255\255\255\255\020\000\020\000\020\000\
    \020\000\020\000\020\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\028\000\028\000\028\000\028\000\
    \028\000\028\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\013\000\
    \015\000\255\255\255\255\017\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec main buf lexbuf =
   __ocaml_lex_main_rec buf lexbuf 0
and __ocaml_lex_main_rec buf lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 111 "ext/ext_sexp.mll"
                     ( 
    update_loc lexbuf 0;
    main (buf : st ) lexbuf  )
# 281 "ext/ext_sexp.ml"

  | 1 ->
# 114 "ext/ext_sexp.mll"
           ( main buf lexbuf  )
# 286 "ext/ext_sexp.ml"

  | 2 ->
# 115 "ext/ext_sexp.mll"
                       (  main buf lexbuf )
# 291 "ext/ext_sexp.ml"

  | 3 ->
# 116 "ext/ext_sexp.mll"
         (
    new_lparen true buf; 
    main buf lexbuf
  )
# 299 "ext/ext_sexp.ml"

  | 4 ->
# 120 "ext/ext_sexp.mll"
        ( 
    new_lparen false buf ; 
    main buf lexbuf 
  )
# 307 "ext/ext_sexp.ml"

  | 5 ->
# 124 "ext/ext_sexp.mll"
        ( 
      new_rparen  buf lexbuf; 
      main buf lexbuf 
  )
# 315 "ext/ext_sexp.ml"

  | 6 ->
# 129 "ext/ext_sexp.mll"
      (
        let pos = Lexing.lexeme_start_p lexbuf in
        scan_string buf.buf pos lexbuf;
        push_atom lexbuf  ( Lit (Buffer.contents  buf.buf)) buf;
        Buffer.clear buf.buf;
        main buf lexbuf
      )
# 326 "ext/ext_sexp.ml"

  | 7 ->
let
# 136 "ext/ext_sexp.mll"
                    s
# 332 "ext/ext_sexp.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 137 "ext/ext_sexp.mll"
    ( push_atom lexbuf (Atom s) buf ; 
      main buf lexbuf
    )
# 338 "ext/ext_sexp.ml"

  | 8 ->
let
# 140 "ext/ext_sexp.mll"
         c
# 344 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 141 "ext/ext_sexp.mll"
      (  error  lexbuf (Illegal_character c))
# 348 "ext/ext_sexp.ml"

  | 9 ->
# 143 "ext/ext_sexp.mll"
        (
    if buf.paren_depth > 0 then 
      error lexbuf Unterminated_paren
    else 
      get_data buf )
# 357 "ext/ext_sexp.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_main_rec buf lexbuf __ocaml_lex_state

and scan_string buf start lexbuf =
   __ocaml_lex_scan_string_rec buf start lexbuf 13
and __ocaml_lex_scan_string_rec buf start lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 150 "ext/ext_sexp.mll"
        ( () )
# 369 "ext/ext_sexp.ml"

  | 1 ->
# 152 "ext/ext_sexp.mll"
      (
        let len = lexeme_len lexbuf - 2 in
        update_loc lexbuf len;

        scan_string buf start lexbuf
      )
# 379 "ext/ext_sexp.ml"

  | 2 ->
# 159 "ext/ext_sexp.mll"
      (
        let len = lexeme_len lexbuf - 3 in
        update_loc lexbuf len;
        scan_string buf start lexbuf
      )
# 388 "ext/ext_sexp.ml"

  | 3 ->
let
# 164 "ext/ext_sexp.mll"
                                                 c
# 394 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 1) in
# 165 "ext/ext_sexp.mll"
      (
        Buffer.add_char buf (char_for_backslash c);
        scan_string buf start lexbuf
      )
# 401 "ext/ext_sexp.ml"

  | 4 ->
let
# 169 "ext/ext_sexp.mll"
                   c1
# 407 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 1)
and
# 169 "ext/ext_sexp.mll"
                                 c2
# 412 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 2)
and
# 169 "ext/ext_sexp.mll"
                                               c3
# 417 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 3)
and
# 169 "ext/ext_sexp.mll"
                                                      s
# 422 "ext/ext_sexp.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos (lexbuf.Lexing.lex_start_pos + 4) in
# 170 "ext/ext_sexp.mll"
      (
        let v = dec_code c1 c2 c3 in
        if v > 255 then
          error lexbuf (Illegal_escape s) ;
        Buffer.add_char buf (Char.chr v);

        scan_string buf start lexbuf
      )
# 433 "ext/ext_sexp.ml"

  | 5 ->
let
# 178 "ext/ext_sexp.mll"
                          c1
# 439 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 2)
and
# 178 "ext/ext_sexp.mll"
                                           c2
# 444 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 3) in
# 179 "ext/ext_sexp.mll"
      (
        let v = hex_code c1 c2 in
        Buffer.add_char buf (Char.chr v);

        scan_string buf start lexbuf
      )
# 453 "ext/ext_sexp.ml"

  | 6 ->
let
# 185 "ext/ext_sexp.mll"
               c
# 459 "ext/ext_sexp.ml"
= Lexing.sub_lexeme_char lexbuf (lexbuf.Lexing.lex_start_pos + 1) in
# 186 "ext/ext_sexp.mll"
      (
        Buffer.add_char buf '\\';
        Buffer.add_char buf c;

        scan_string buf start lexbuf
      )
# 468 "ext/ext_sexp.ml"

  | 7 ->
# 193 "ext/ext_sexp.mll"
      (
        update_loc lexbuf 0;
        Buffer.add_char buf lf;

        scan_string buf start lexbuf
      )
# 478 "ext/ext_sexp.ml"

  | 8 ->
# 200 "ext/ext_sexp.mll"
      (
        let ofs = lexbuf.lex_start_pos in
        let len = lexbuf.lex_curr_pos - ofs in
        Buffer.add_substring buf (Bytes.to_string lexbuf.lex_buffer) ofs len;

        scan_string buf start lexbuf
      )
# 489 "ext/ext_sexp.ml"

  | 9 ->
# 208 "ext/ext_sexp.mll"
      (
        error lexbuf Unterminated_string
      )
# 496 "ext/ext_sexp.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_scan_string_rec buf start lexbuf __ocaml_lex_state

;;

# 212 "ext/ext_sexp.mll"
  

    let token  lexbuf  =
      List.rev @@ main { 
        buf = Buffer.create 256 ;
        sexps = Stack.create () ; 
        paren_depth = 0; 
        top = [];
        has_prime = false } lexbuf
    let from_string str = 
      token (Lexing.from_string str)    
    let from_file file = 
      let in_channel =  open_in file in 
      match  token (Lexing.from_channel in_channel) with 
      | exception  e -> close_in in_channel; raise e 
      | sexps -> close_in in_channel ; sexps

# 521 "ext/ext_sexp.ml"
