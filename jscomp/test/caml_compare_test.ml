
type  u  = A of int | B of int * bool | C of int 

let function_equal_test = try ((fun x -> x + 1) = (fun x -> x + 2)) with
                         | Invalid_argument "equal: functional value" -> true
                         | _ -> false

let suites = Mt.[
    "option", (fun _ -> Eq(true, None < Some 1));
    "option2", (fun _ -> Eq(true, Some 1 < Some 2));
    "list0", (fun _ -> Eq(true, [1] > []));
    "listeq", (fun _ -> Eq(true, [1;2;3] = [1;2;3]));
    "listneq", (fun _ -> Eq(true, [1;2;3] > [1;2;2]));
    "custom_u", (fun _ -> Eq(true, ( A 3  ,  B (2,false) , C 1)  > ( A 3, B (2,false) , C 0 )));
    "custom_u2", (fun _ -> Eq(true, ( A 3  ,  B (2,false) , C 1)  = ( A 3, B (2,false) , C 1 )));
    "function", (fun _ -> Eq(true, function_equal_test));
    __LOC__ , begin fun _ -> 
        Eq(true, None < Some 1)
    end;
    (*JS WAT 
        {[
            0 < [1]
            true 
            0 < [1,30]
            false 
        ]}
    *)
    __LOC__, begin fun _ -> 
        Eq(true, None < Some [|1;30|] )
    end; 
    __LOC__, begin fun _ -> 
        Eq(true,  Some [|1;30|] > None  )
    end; 
    __LOC__ , begin fun _ -> 
        Eq(true, [2;6;1;1;2;1;4;2;1] < [2;6;1;1;2;1;4;2;1;409])
    end;
    __LOC__ , begin fun _ -> 
        Eq(true,  [2;6;1;1;2;1;4;2;1;409] > [2;6;1;1;2;1;4;2;1])
    end;
    
    __LOC__, begin fun _ -> 
        Eq(false, None = Some [|1;30|] )
    end; 
    __LOC__, begin fun _ -> 
        Eq(false,  Some [|1;30|] = None  )
    end; 
    __LOC__ , begin fun _ -> 
        Eq(false, [2;6;1;1;2;1;4;2;1] = [2;6;1;1;2;1;4;2;1;409])
    end;
    __LOC__ , begin fun _ -> 
        Eq(false,  [2;6;1;1;2;1;4;2;1;409] = [2;6;1;1;2;1;4;2;1])
    end;

    "cmp_id", (fun _ -> Eq (compare [%bs.obj {x=1; y=2}] [%bs.obj {x=1; y=2}], 0));
    "cmp_val", (fun _ -> Eq (compare [%bs.obj {x=1}] [%bs.obj {x=2}], -1));
    "cmp_val2", (fun _ -> Eq (compare [%bs.obj {x=2}] [%bs.obj {x=1}], 1));
    "cmp_empty", (fun _ -> Eq (compare [%bs.raw "{}"] [%bs.raw "{}"], 0));
    "cmp_empty2", (fun _ -> Eq (compare [%bs.raw "{}"] [%bs.raw "{x:1}"], -1));
    "cmp_swap", (fun _ -> Eq (compare [%bs.obj {x=1; y=2}] [%bs.obj {y=2; x=1}], 0));
    "cmp_size", (fun _ -> Eq (compare [%bs.raw "{x:1}"] [%bs.raw "{x:1, y:2}"], -1));
    "cmp_size2", (fun _ -> Eq (compare [%bs.raw "{x:1, y:2}"] [%bs.raw "{x:1}"], 1));
    "cmp_order", (fun _ -> Eq (compare [%bs.obj {x=0; y=1}] [%bs.obj {x=1; y=0}], -1));
    "cmp_order2", (fun _ -> Eq (compare [%bs.obj {x=1; y=0}] [%bs.obj {x=0; y=1}], 1));
    "cmp_in_list", (fun _ -> Eq (compare [[%bs.obj {x=1}]] [[%bs.obj {x=2}]], -1));
    "cmp_in_list2", (fun _ -> Eq (compare [[%bs.obj {x=2}]] [[%bs.obj {x=1}]], 1));
    "cmp_with_list", (fun _ -> Eq (compare [%bs.obj {x=[0]}] [%bs.obj {x=[1]}], -1));
    "cmp_with_list2", (fun _ -> Eq (compare [%bs.obj {x=[1]}] [%bs.obj {x=[0]}], 1));
    "eq_id", (fun _ -> Ok ([%bs.obj {x=1; y=2}] = [%bs.obj {x=1; y=2}]));
    "eq_val", (fun _ -> Eq ([%bs.obj {x=1}] = [%bs.obj {x=2}], false));
    "eq_val2", (fun _ -> Eq ([%bs.obj {x=2}] = [%bs.obj {x=1}], false));
    "eq_empty", (fun _ -> Eq ([%bs.raw "{}"] = [%bs.raw "{}"], true));
    "eq_empty2", (fun _ -> Eq ([%bs.raw "{}"] = [%bs.raw "{x:1}"], false));
    "eq_swap", (fun _ -> Ok ([%bs.obj {x=1; y=2}] = [%bs.obj {y=2; x=1}]));
    "eq_size", (fun _ -> Eq ([%bs.raw "{x:1}"] = [%bs.raw "{x:1, y:2}"], false));
    "eq_size2", (fun _ -> Eq ([%bs.raw "{x:1, y:2}"] = [%bs.raw "{x:1}"], false));
    "eq_in_list", (fun _ -> Eq ([[%bs.obj {x=1}]] = [[%bs.obj {x=2}]], false));
    "eq_in_list2", (fun _ -> Eq ([[%bs.obj {x=2}]] = [[%bs.obj {x=2}]], true));
    "eq_with_list", (fun _ -> Eq ([%bs.obj {x=[0]}] = [%bs.obj {x=[0]}], true));
    "eq_with_list2", (fun _ -> Eq ([%bs.obj {x=[0]}] = [%bs.obj {x=[1]}], false));

    __LOC__ , begin fun _ -> 
        Eq(true, None = Js.Nullable.null)
    end;
    __LOC__ , begin fun _ -> 
        Eq(true, None = Js.Nullable.undefined)
    end;
    __LOC__ , begin fun _ -> 
        Eq(true, Js.Nullable.null = Js.Nullable.undefined)
    end;
    __LOC__ , begin fun _ -> 
        Eq(false, Js.Nullable.null == Js.Nullable.undefined)
    end;
    __LOC__ , begin fun _ ->
        let n : int option = (Obj.magic Js.Nullable.null) in
        let u : int option = (Obj.magic Js.Nullable.undefined) in
        Eq(true, n = u)
    end;
    __LOC__ , begin fun _ -> 
        Eq(0, compare Js.Nullable.null Js.Nullable.undefined)
    end;
]
;;



Mt.from_pair_suites __FILE__ suites
