(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)

open Ast_helper

let not_supported loc =
  Bs_syntaxerr.err loc Not_supported_in_bs_deriving


let current_name_set : string list ref = ref []

let loc = Location.none 

let (+>) = Typ.arrow Nolabel

type lid = Longident.t Asttypes.loc


let record_to_value = "record_to_value"
let variant_to_value = "variant_to_value"
let shape = "shape"
let js_dyn = "Bs_dyn"
let value = "value"
let record_shape = "record_shape"
let to_value = "_to_value"
let to_value_ = "_to_value_"
let shape_of_variant = "shape_of_variant"
let shape_of_record = "shape_of_record"
let option_to_value = "option_to_value"
(**
   {[Ptyp_constr of Longident.t loc * core_type list ]}
   ['u M.t]
*)


let bs_attrs = [Ast_attributes.bs]

(** template for 
    {[fun (value : t) -> 
      match value with 
        cases 
    ]}
*)
let js_dyn_value_type () =
  Typ.constr {txt = Longident.Ldot ((Lident  js_dyn), value) ; loc} []
let get_js_dyn_record_shape_type () = 
  Typ.constr {txt = Ldot (Lident js_dyn, record_shape); loc} []
let js_dyn_shape_of_variant () = 
  Exp.ident {txt = Ldot (Lident js_dyn, shape_of_variant); loc}
let js_dyn_shape_of_record () = 
  Exp.ident {txt = Ldot (Lident js_dyn, shape_of_record); loc}

let js_dyn_to_value_type ty  = 
  Typ.arrow Nolabel ty  (js_dyn_value_type ())
let js_dyn_to_value_uncurry_type ty = 
  Typ.arrow Nolabel ~attrs:bs_attrs ty (js_dyn_value_type ())

let js_dyn_variant_to_value () = 
  Exp.ident {txt = Ldot (Lident js_dyn, variant_to_value); loc}

let js_dyn_option_to_value () = 
  Exp.ident {txt = Ldot (Lident js_dyn, option_to_value); loc}

let js_dyn_tuple_to_value i = 
  Exp.ident {txt = Ldot (
      Lident js_dyn,
      "tuple_" ^ string_of_int i ^ "_to_value"); loc}


let bs_apply1 f v = 
  Exp.apply f [Nolabel,v] ~attrs:bs_attrs



(** [M.t]-> [M.t_to_value ] *)

let fn_of_lid  suffix (x : lid) : lid = 
  match x with
  | { txt = Lident name} 
    -> { x with  txt = Lident (name ^ suffix )}
  | { txt = Ldot (v,name)} 
    -> {x with txt = Ldot (v,  name ^ suffix )}
  | { txt = Lapply _} -> not_supported x.loc 

let rec exp_of_core_type prefix 
    ({ptyp_loc = loc} as x : Parsetree.core_type)
  : Parsetree.expression = 
  match x.ptyp_desc with 
  | Ptyp_constr (
      {txt = 
         Lident (
           "int" 
         | "int32" 
         | "int64" 
         | "nativeint"
         | "bool"
         | "float"
         | "char"
         | "string" 
           as name );
       loc }, ([] as params))
  | Ptyp_constr (
      {txt = 
         Lident (
           "option" 
         | "list" 
         | "array" 
           as name );
       loc }, ([_] as params))
    -> exp_of_core_type prefix 
         {x with 
          ptyp_desc =
            Ptyp_constr ({txt =  Ldot(Lident js_dyn,name);loc}, params)}
  | Ptyp_constr ({txt ; loc} as lid, []) -> 
    Exp.ident (fn_of_lid prefix lid)       
  | Ptyp_constr (lid, params)
    -> 
    Exp.apply (Exp.ident (fn_of_lid prefix lid))
      (Ext_list.map (fun x -> Asttypes.Nolabel,exp_of_core_type prefix x ) params) 
  | Ptyp_tuple lst -> 
    begin match lst with 
    | [x] -> exp_of_core_type prefix x 
    | [] -> assert false 
    | _ -> 
      let len = List.length lst in 
      if len > 6 then 
        Location.raise_errorf ~loc "tuple arity > 6 not supported yet"
      else 
        let fn = js_dyn_tuple_to_value len in 
        let args = Ext_list.map (fun x -> Asttypes.Nolabel, exp_of_core_type prefix x) lst in 
        Exp.apply fn args 
    end


  | _ -> assert false



(** return an expression node of array type *)
let exp_of_core_type_exprs 
    (core_type_exprs : (Parsetree.core_type * Parsetree.expression) list) 
  : Parsetree.expression  = 
    Exp.array 
      (Ext_list.fold_right (fun (core_type, exp) acc -> 
           bs_apply1
             (exp_of_core_type to_value  core_type) exp

           (* depends on [core_type] is in recursive name set or not ,
              if not, then uncurried application, otherwise, since 
              the uncurried version is not in scope yet, we 
              have to use the curried version
              the complexity is necessary
              think about such scenario:
              {[
                type nonrec t = A of t (* t_to_value *)
                and u = t (* t_to_value_ *)
              ]}
           *)
           :: acc 
       ) core_type_exprs [])

let destruct_constructor_declaration 
    ({pcd_name = {txt ;loc}; pcd_args} : Parsetree.constructor_declaration)  = 
  let last_i, core_type_exprs, pats = match pcd_args with
    | Pcstr_tuple core_types ->
        List.fold_left (fun (i,core_type_exps, pats) core_type -> 
          let  txt = "a" ^ string_of_int i  in
          (i+1, (core_type, Exp.ident {txt = Lident txt  ;loc}) :: core_type_exps, 
           Pat.var {txt ; loc} :: pats )
        ) (0, [], []) core_types
    | Pcstr_record _ ->
        (0, [], []) in 
  let core_type_exprs, pats  = List.rev core_type_exprs, List.rev pats in
  Pat.construct {txt = Lident txt ; loc}
    (if last_i = 0 then 
       None
     else if last_i = 1 then 
       Some (List.hd pats) 
     else
       Some (Pat.tuple pats)  ), core_type_exprs


let case_of_ctdcl (ctdcls : Parsetree.constructor_declaration list) = 
    Exp.function_ 
      (List.mapi (fun i ctdcl -> 
           let pat, core_type_exprs = destruct_constructor_declaration ctdcl in 
           Exp.case pat 
             (Exp.apply 
                (js_dyn_variant_to_value ())
                [(Nolabel, Exp.ident {txt = Lident shape ; loc});
                 (Nolabel, Ast_derive_util.lift_int i);
                 (Nolabel, exp_of_core_type_exprs core_type_exprs);
                ]
             )) ctdcls
      )
let record args = 
  Exp.apply 
    (Exp.ident {txt = Ldot (Lident js_dyn, record_to_value ); loc})
    [Nolabel, Exp.ident {txt = Lident shape ; loc};
     (Nolabel,  args)
    ]      


let fun_1 name = 
  Exp.fun_ Nolabel None ~attrs:bs_attrs 
    (Pat.var {txt = "x"; loc})
    (Exp.apply (Exp.ident name)
       [Nolabel,(Exp.ident {txt = Lident "x"; loc})])

let record_exp  name core_type  labels : Ast_structure.t = 
  let arg_name : string = "args" in
  let core_type_exprs, labels = 
    Ast_derive_util.destruct_label_declarations ~loc arg_name labels in

  [Str.value Nonrecursive @@ 
   [Vb.mk 
     (Pat.var {txt = shape;  loc}) 
     (Exp.apply (js_dyn_shape_of_record ())
        [Nolabel, (Ast_derive_util.lift_string_list_to_array labels)]
     ) ];
   Str.value Nonrecursive @@ 
   [Vb.mk (Pat.var {txt = name ^ to_value_  ; loc })
      (Ast_derive_util.mk_fun ~loc core_type arg_name 
         (record (exp_of_core_type_exprs core_type_exprs))
      )];
   Str.value Nonrecursive @@
   [Vb.mk (Pat.var {txt = name ^ to_value; loc})
      ( fun_1 { txt = Lident (name ^ to_value_) ;loc})
   ]        
  ]



let init ()  =
  Ast_derive.update 
    "dynval"
    begin fun (x : Parsetree.expression option) -> 
      match x with 
      | Some {pexp_loc = loc} 
        -> Location.raise_errorf ~loc "such configuration is not supported"
      | None -> 
        {Ast_derive.structure_gen = 
           begin  fun (tdcl  : Parsetree.type_declaration list) explict_nonrec ->
             begin match tdcl with 
               | [tdcl] -> 
                 let core_type = Ast_derive_util.core_type_of_type_declaration  tdcl in 
                 let name = tdcl.ptype_name.txt in
                 let loc = tdcl.ptype_loc in 
                 let signatures = 
                   [Sig.value ~loc 
                      (Val.mk {txt =  name ^ to_value  ; loc}
                         (js_dyn_to_value_uncurry_type core_type))
                   ] in
                 let constraint_ strs = 
                   [Ast_structure.constraint_  ~loc strs signatures] in
                 begin match tdcl with 
                   | {ptype_params = [];
                      ptype_kind  = Ptype_variant cd;
                      ptype_loc = loc;
                     } -> 
                     if explict_nonrec then 
                       let names, arities =
                         Ext_list.fold_right 
                           (fun (ctdcl : Parsetree.constructor_declaration) 
                             (names,arities) -> 
                             let len = match ctdcl.pcd_args with
                                 | Pcstr_tuple l -> List.length l
                                 | Pcstr_record l -> List.length l in
                             ctdcl.pcd_name.txt :: names, 
                             len :: arities
                           ) cd ([],[]) in 
                       constraint_ 
                         [
                           Str.value Nonrecursive @@ 
                           [Vb.mk (Pat.var {txt = shape ; loc})
                              (      Exp.apply (js_dyn_shape_of_variant ())
                                       [ Nolabel, (Ast_derive_util.lift_string_list_to_array names);
                                         Nolabel, (Ast_derive_util.lift_int_list_to_array arities )
                                       ])];
                           Str.value Nonrecursive @@ 
                           [Vb.mk (Pat.var {txt = name ^ to_value_  ; loc})
                              (case_of_ctdcl cd)
                           ];
                           Str.value Nonrecursive @@
                           [Vb.mk (Pat.var {txt = name ^ to_value; loc})
                              ( fun_1 { txt = Lident (name ^ to_value_) ;loc})
                           ]        
                         ]
                     else 
                       []
                   | {ptype_params = []; 
                      ptype_kind = Ptype_abstract; 
                      ptype_manifest = Some x 
                     } -> (** case {[ type t = int ]}*)
                     constraint_ 
                       [
                         Str.value Nonrecursive @@ 
                         [Vb.mk (Pat.var {txt = name ^ to_value  ; loc})
                            (exp_of_core_type to_value x)
                         ]
                       ]

                   |{ptype_params = [];
                     ptype_kind  = Ptype_record labels;
                     ptype_loc = loc;
                    } -> 
                     if explict_nonrec then constraint_ (record_exp name core_type labels) 
                     else []

                   | _ -> 
                     []
                 end
               | _ -> []
              end
            end
              ; 
           expression_gen =  Some begin fun core_type -> 
               exp_of_core_type to_value core_type
             end;
           signature_gen = 
             begin fun 
               (tdcls : Parsetree.type_declaration list)
               (explict_nonrec : bool) -> 
               let handle_tdcl tdcl = 
                 let core_type = Ast_derive_util.core_type_of_type_declaration tdcl in 
                 let name = tdcl.ptype_name.txt in
                 let loc = tdcl.ptype_loc in 
                 Sig.value ~loc (Val.mk {txt = name ^ to_value  ; loc}
                                   (js_dyn_to_value_uncurry_type core_type)) in 
               Ext_list.map handle_tdcl tdcls 

             end

         }
     end
