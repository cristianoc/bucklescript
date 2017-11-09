open Misc
open Asttypes
open Parsetree
open Types
open Typedtree
open Btype
open Ctype

let fprintf = Format.fprintf
let sprintf = Format.sprintf
let longident = Printtyp.longident
let super_report_unification_error = Printtyp.super_report_unification_error
let reset_and_mark_loops = Printtyp.reset_and_mark_loops
let type_expr = Printtyp.type_expr

(* taken from https://github.com/BuckleScript/ocaml/blob/d4144647d1bf9bc7dc3aadc24c25a7efa3a67915/typing/typecore.ml#L3769 *)
(* modified branches are commented *)
let report_error env ppf = function
  | Typecore.Polymorphic_label lid ->
      fprintf ppf "@[The record field %a is polymorphic.@ %s@]"
        longident lid "You cannot instantiate it in a pattern."
  | Constructor_arity_mismatch(lid, expected, provided) ->
      (* modified *)
      fprintf ppf
       "@[This variant constructor, %a, expects %i %s; here, we've %sfound %i.@]"
       longident lid expected (if expected == 1 then "argument" else "arguments") (if provided < expected then "only " else "") provided
  | Label_mismatch(lid, trace) ->
      super_report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "The record field %a@ belongs to the type"
                   longident lid)
        (function ppf ->
           fprintf ppf "but is mixed here with fields of type")
  | Pattern_type_clash trace ->
      super_report_unification_error ppf env trace
        (function ppf ->
          fprintf ppf "This pattern matches values of type")
        (function ppf ->
          fprintf ppf "but a pattern was expected which matches values of type")
  | Or_pattern_type_clash (id, trace) ->
      super_report_unification_error ppf env trace
        (function ppf ->
          fprintf ppf "The variable %s on the left-hand side of this or-pattern has type" (Ident.name id))
        (function ppf ->
          fprintf ppf "but on the right-hand side it has type")
  | Multiply_bound_variable name ->
      fprintf ppf "Variable %s is bound several times in this matching" name
  | Orpat_vars _ as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
  | Expr_type_clash trace ->
      (* modified *)
      if Super_reason_react.state_escape_scope trace then
        fprintf ppf "@[<v>\
          @[@{<info>Is this a ReasonReact reducerComponent or component with retained props?@}@ \
          If so, is the type for state, retained props or action declared _after_ the component declaration?@ \
          Moving these types above the component declaration should resolve this!@]@,@,\
          @[@{<info>Here's the original error message@}@]@,\
        @]"
      else if Super_reason_react.is_array_wanted_reactElement trace then
        fprintf ppf "@[<v>\
          @[@{<info>Are you passing an array as a ReasonReact DOM (lower-case) component's children?@}@ If not, disregard this.@ \
          If so, please use `ReasonReact.createDomElement`:@ https://reasonml.github.io/reason-react/docs/en/children.html@]@,@,\
          @[@{<info>Here's the original error message@}@]@,\
        @]";
      super_report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "This is:")
        (function ppf ->
           fprintf ppf "But somewhere wanted:")
  | Apply_non_function typ ->
      (* modified *)
      reset_and_mark_loops typ;
      begin match (repr typ).desc with
        Tarrow (_, _inputType, returnType, _) ->
          let rec countNumberOfArgs count {desc} = match desc with
          | Tarrow (_, _inputType, returnType, _) -> countNumberOfArgs (count + 1) returnType
          | _ -> count
          in
          let countNumberOfArgs = countNumberOfArgs 1 in
          let acceptsCount = countNumberOfArgs returnType in
          fprintf ppf "@[<v>@[<2>This function has type@ %a@]"
            type_expr typ;
          fprintf ppf "@ @[It only accepts %i %s; here, it's called with more.@ %s@]@]"
                      acceptsCount (if acceptsCount == 1 then "argument" else "arguments") "Maybe you forgot a semicolon?"
      | _ ->
          fprintf ppf "@[<v>@[<2>This expression has type@ %a@]@ %s@]"
            type_expr typ
            "It seems to have been called like a function? Maybe you forgot a semicolon somewhere?"
      end
  | Apply_wrong_label (l, ty) ->
      let print_label ppf = function
        | Nolabel -> fprintf ppf "without label"
        | l ->
            fprintf ppf "with label %s" (prefixed_label_name l)
      in
      reset_and_mark_loops ty;
      fprintf ppf
        "@[<v>@[<2>The function applied to this argument has type@ %a@]@.\
          This argument cannot be applied %a@]"
        type_expr ty print_label l
  | Label_multiply_defined s ->
      fprintf ppf "The record field label %s is defined several times" s
  | Label_missing labels ->
      let print_labels ppf =
        List.iter (fun lbl -> fprintf ppf "@ %s" (Ident.name lbl)) in
      fprintf ppf "@[<hov>Some record fields are undefined:%a@]"
        print_labels labels
  | Label_not_mutable lid ->
      fprintf ppf "The record field %a is not mutable" longident lid
  | Wrong_name _ as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
  | Name_type_mismatch (kind, lid, tp, tpl) ->
      let name = if kind = "record" then "field" else "constructor" in
      Printtyp.report_ambiguous_type_error ppf env tp tpl
        (function ppf ->
           fprintf ppf "The %s %a@ belongs to the %s type"
             name longident lid kind)
        (function ppf ->
           fprintf ppf "The %s %a@ belongs to one of the following %s types:"
             name longident lid kind)
        (function ppf ->
           fprintf ppf "but a %s was expected belonging to the %s type"
             name kind)
  | Invalid_format msg ->
      fprintf ppf "%s" msg
  | Undefined_method _ as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
  | Undefined_inherited_method _ as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
  | Virtual_class cl ->
      fprintf ppf "Cannot instantiate the virtual class %a"
        longident cl
  | Unbound_instance_variable _ as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
  | Instance_variable_not_mutable (b, v) ->
      if b then
        fprintf ppf "The instance variable %s is not mutable" v
      else
        fprintf ppf "The value %s is not an instance variable" v
  | Not_subtype(tr1, tr2) ->
      Printtyp.report_subtyping_error ppf env tr1 "is not a subtype of" tr2
  | Outside_class ->
      fprintf ppf "This object duplication occurs outside a method definition"
  | Value_multiply_overridden v ->
      fprintf ppf "The instance variable %s is overridden several times" v
  | Coercion_failure (ty, ty', trace, b) ->
      super_report_unification_error ppf env trace
        (function ppf ->
           let ty, ty' = Printtyp.prepare_expansion (ty, ty') in
           fprintf ppf
             "This expression cannot be coerced to type@;<1 2>%a;@ it has type"
           (Printtyp.type_expansion ty) ty')
        (function ppf ->
           fprintf ppf "but is here used with type");
      if b then
        fprintf ppf ".@.@[<hov>%s@ %s@]"
          "This simple coercion was not fully general."
          "Consider using a double coercion."
  | Too_many_arguments (in_function, ty) ->
      reset_and_mark_loops ty;
      if in_function then begin
        fprintf ppf "This function expects too many arguments,@ ";
        fprintf ppf "it should have type@ %a"
          type_expr ty
      end else begin
        fprintf ppf "This expression should not be a function,@ ";
        fprintf ppf "the expected type is@ %a"
          type_expr ty
      end
  | Abstract_wrong_label (l, ty) ->
      let label_mark = function
        | Nolabel -> "but its first argument is not labelled"
        | l -> sprintf "but its first argument is labelled %s"
                       (prefixed_label_name l) in
      reset_and_mark_loops ty;
      fprintf ppf "@[<v>@[<2>This function should have type@ %a@]@,%s@]"
      type_expr ty (label_mark l)
  | Scoping_let_module(id, ty) ->
      reset_and_mark_loops ty;
      fprintf ppf
       "This `let module' expression has type@ %a@ " type_expr ty;
      fprintf ppf
       "In this type, the locally bound module name %s escapes its scope" id
  | Masked_instance_variable lid ->
      fprintf ppf
        "The instance variable %a@ \
         cannot be accessed from the definition of another instance variable"
        longident lid
  | Private_type ty ->
      fprintf ppf "Cannot create values of the private type %a" type_expr ty
  | Private_label (lid, ty) ->
      fprintf ppf "Cannot assign field %a of the private type %a"
        longident lid type_expr ty
  | Not_a_variant_type lid ->
      fprintf ppf "The type %a@ is not a variant type" longident lid
  | Incoherent_label_order ->
      fprintf ppf "This function is applied to arguments@ ";
      fprintf ppf "in an order different from other calls.@ ";
      fprintf ppf "This is only allowed when the real type is known."
  | Less_general (kind, trace) ->
      super_report_unification_error ppf env trace
        (fun ppf -> fprintf ppf "This %s has type" kind)
        (fun ppf -> fprintf ppf "which is less general than")
  | Modules_not_allowed ->
      fprintf ppf "Modules are not allowed in this pattern."
  | Cannot_infer_signature ->
      fprintf ppf
        "The signature for this packaged module couldn't be inferred."
  | Not_a_packed_module ty ->
      fprintf ppf
        "This expression is packed module, but the expected type is@ %a"
        type_expr ty
  | Recursive_local_constraint trace ->
      super_report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "Recursive local constraint when unifying")
        (function ppf ->
           fprintf ppf "with")
  | Unexpected_existential ->
      fprintf ppf
        "Unexpected existential"
  | Unqualified_gadt_pattern (tpath, name) ->
      fprintf ppf "@[The GADT constructor %s of type %a@ %s.@]"
        name Printtyp.path tpath
        "must be qualified in this pattern"
  | Invalid_interval ->
      fprintf ppf "@[Only character intervals are supported in patterns.@]"
  | Invalid_for_loop_index ->
      fprintf ppf
        "@[Invalid for-loop index: only variables and _ are allowed.@]"
  | No_value_clauses ->
      fprintf ppf
        "None of the patterns in this 'match' expression match values."
  | Exception_pattern_below_toplevel ->
      fprintf ppf
        "@[Exception patterns must be at the top level of a match case.@]"
  | Inlined_record_escape ->
      fprintf ppf
        "@[This form is not allowed as the type of the inlined record could \
         escape.@]"
  | Inlined_record_expected ->
      fprintf ppf
        "@[This constructor expects an inlined record argument.@]"
  | Unrefuted_pattern pat ->
      fprintf ppf
        "@[%s@ %s@ %a@]"
        "This match case could not be refuted."
        "Here is an example of a value that would reach it:"
        Parmatch.top_pretty pat
  | Invalid_extension_constructor_payload ->
      fprintf ppf
        "Invalid [%%extension_constructor] payload, a constructor is expected."
  | Not_an_extension_constructor ->
      fprintf ppf
        "This constructor is not an extension constructor."
  | Literal_overflow ty ->
      fprintf ppf "Integer literal exceeds the range of representable \
                   integers of type %s" ty
  | Unknown_literal (n, m) ->
      fprintf ppf "Unknown modifier '%c' for literal %s%c" m n m
  | Illegal_letrec_pat ->
      fprintf ppf
        "Only variables are allowed as left-hand side of `let rec'"
  | Illegal_letrec_expr ->
      fprintf ppf
        "This kind of expression is not allowed as right-hand side of `let rec'"
  | Illegal_class_expr ->
      fprintf ppf "This kind of recursive class expression is not allowed"

let report_error env ppf err =
  Printtyp.wrap_printing_env env (fun () -> report_error env ppf err)

(* This will be called in super_main. This is how you'd override the default error printer from the compiler & register new error_of_exn handlers *)
let setup () =
  Location.register_error_of_exn
    (function
      | Typecore.Error (loc, env, err) ->
        Some (Super_location.error_of_printer loc (report_error env) err)
      | Typecore.Error_forward err ->
        Some err
      | _ ->
        None
    )
