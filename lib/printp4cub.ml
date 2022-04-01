open Format
open Poulet4.AST
(* open Poulet4.P4Field *)
(***********************************************
              P4cub.ml -> Sexp
 ***********************************************)
let print_bool p b = 
    let s = 
    match b with 
    | true -> "true"
    | false -> "false"
  in fprintf p "%s" s

let print_bigint p n =
  fprintf p "%s" (Bignum.to_string_accurate (Bignum.of_bigint n))

let print_option printa p (o: ('a option)) = 
  match o with
  | None -> fprintf p "Option<%s>" "None"
  | Some a -> fprintf p "Option<%a>" printa a
let print_uop p u = 
  let s = 
  match u with
  | Expr.Not -> "Not"
  | Expr.BitNot -> "BitNot"
  | Expr.UMinus -> "UMinus"
  | Expr.IsValid -> "IsValid"
  | Expr.SetValid -> "SetValid"
  | Expr.SetInValid -> "SetInValid"
  | Expr.NextIndex -> "NextIndex"
  | Expr.Size -> "Size"
  in
fprintf p "%s" s

let print_bop p b = 
 let s = 
  match b with
  | Expr.Plus -> "Plus"
  | Expr.PlusSat -> "PlusSat"
  | Expr.Minus -> "Minus"
  | Expr.MinusSat -> "MinusSat"
  | Expr.Times -> "Times"
  | Expr.Shl -> "Shl"
  | Expr.Shr -> "Shr"
  | Expr.Le -> "Le"
  | Expr.Ge -> "Ge"
  | Expr.Lt -> "Lt"
  | Expr.Gt -> "Gt"
  | Expr.Eq -> "Eq"
  | Expr.NotEq -> "NotEq"
  | Expr.BitAnd -> "BitAnd"
  | Expr.BitXor -> "BitXor"
  | Expr.BitOr -> "BitOr"
  | Expr.PlusPlus -> "PlusPlus"
  | Expr.And -> "And"
  | Expr.Or -> "Or"
  in
  fprintf p "%s" s

let print_matchkind p m = 
  let s = 
  match m with
  | Expr.MKExact -> "MKExact"
  | Expr.MKTernary -> "MKTernary"
  | Expr.MKLpm -> "MKLpm"
  in
fprintf p "%s" s

let print_paramarg printa printb p (ab : ('a,'b) paramarg) = 
  match ab with
  | PAIn a -> fprintf p "PAIn <%a>" printa a
  | PAOut b -> fprintf p "PAOut <%a>" printb b
  | PAInOut b -> fprintf p "PAInOut <%a>" printb b
  | PADirLess a -> fprintf p "PADirLess <%a>" printa a



let print_list ?(sep="") f p l =
  let print_item b x =
    if b then fprintf p "%s@ " sep;
    f p x ;
    true in
  ignore (List.fold_left print_item false l)

let print_string p s =
  fprintf p "%s" s

let print_field print1 print2 p (f: ('a, 'b) F.f)  = 
  fprintf p "@[%a = %a@]" 
    print1 (fst f)
    print2 (snd f)

let print_fields print1 print2 p (f : ('a, 'b) F.fs) = 
   if (List.length f <> 0) then
    fprintf p "<%a>" (print_list ~sep:"," (print_field print1 print2)) f
  else ()


let print_arrow printk printa printb printr p (ar: ('k,'a,'b,'r) arrow) =
  fprintf p "@[paramargs: <%a>, rtrns: <%a>@]"
    (print_fields printk (print_paramarg printa printb)) ar.paramargs
    (print_option printr) ar.rtrns 


let print_string_string_field p (f: (string, string) F.f) =
  print_field print_string print_string p f 


let print_string_string_fields p (f: (string, string) F.fs ) =
  if (List.length f <> 0) then
    fprintf p "<%a>" (print_list ~sep:"," print_string_string_field) f
  else ()  




let rec print_type p (t:Expr.t) = 
  match t with 
  | Expr.TBool -> fprintf p "%s" "TBool"
  | Expr.TBit i -> fprintf p "TBit: @[%a@]" print_bigint i 
  | Expr.TInt i -> fprintf p "TInt: @[%a@]" print_bigint i 
  | Expr.TError -> fprintf p "%s" "TError" 
  | Expr.TTuple lt -> fprintf p "TTuple <%a>" (print_list ~sep:"*" print_type) lt
  | Expr.TStruct ts -> fprintf p "TStruct <%a>" (print_fields print_string print_type) ts  
  | Expr.THeader th -> fprintf p "THeader <%a>" (print_fields print_string print_type) th  
  | Expr.THeaderStack (ths, l) -> fprintf p "THeaderStack <%a> [%a]" 
                                  (print_fields print_string print_type) ths
                                  print_bigint l  

  | Expr.TVar n -> fprintf p "Tvar %s" n 

let print_params p (pa: Expr.params) = 
  print_fields print_string (print_paramarg print_type print_type) p pa

let print_arrowT = print_arrow print_string print_type print_type print_type

let rec print_ct p (c: Expr.ct) = 
  match c with
  | Expr.CTType typ -> fprintf p "CTType <%a>" print_type typ
  | Expr.CTControl (fs1, fs2, pa) ->
    fprintf p "CTControl <%a> <extern: %a> (%a)"
      (print_fields print_string print_ct) fs1 
      (print_fields print_string print_string) fs2
      print_params pa
  | Expr.CTParser (fs1, fs2, pa) ->
    fprintf p "CTParser <%a> <extern: %a> (%a)"
      (print_fields print_string print_ct) fs1 
      (print_fields print_string print_string) fs2
      print_params pa
  | Expr.CTPackage fs -> 
    fprintf p "CTPackage <%a>"
      (print_fields print_string print_ct) fs 
  | Expr.CTExtern s ->
    fprintf p "CTExtern %a"
      print_string s

let print_constructor_params = 
  print_fields print_string print_ct

let rec print_expr p (e: 'a Expr.e) = 
  match e with 
  | Expr.EBool (b, _) -> fprintf p "EBool %a" print_bool b
  | Expr.EBit (w, i, _) -> fprintf p "EBit <%a> %a" print_bigint w print_bigint i
  | Expr.EInt (w, i, _) -> fprintf p "EInt <%a> %a" print_bigint w print_bigint i
  | Expr.EVar (typ, x, _) -> fprintf p "EVar : <%a> %a" print_type typ print_string x
  | Expr.ESlice (e', l, r , _) -> fprintf p "ESlice : <%a>[%a : %a]"
                                print_expr e'
                                print_bigint l
                                print_bigint r

  | Expr.ECast (typ, e', _) -> fprintf p "ECast <%a> %a" 
                                print_type typ
                                print_expr e'
  | Expr.EUop (typ, u, e', _) -> fprintf p "EUop <%a> %a @[%a @]"
                                  print_type typ
                                  print_uop u
                                  print_expr e'

  | Expr.EBop (typ, b, e1, e2, _) -> 
        fprintf p "EBop <%a> %a (@[%a@] @[%a@])"
        print_type typ
        print_bop b
        print_expr e1 
        print_expr e2
  
  | Expr.ETuple (el,_) -> 
        fprintf p "ETuple @[%a@]"
        (print_list ~sep:"," (print_expr)) el 
  
  | Expr.EStruct (fs,_) ->
        fprintf p "EStruct @[%a@]"
        (print_fields print_string print_expr) fs
  | Expr.EHeader (fs, e, _) ->
        fprintf p "EStruct <Valid: %a> @[%a@]"
        print_expr e
        (print_fields print_string print_expr) fs
  | Expr.EExprMember (typ, m, a, _) ->
        fprintf p "EExprMember <%a> @[%a@].%a"
        print_type typ
        print_expr a 
        print_string m
  | Expr.EError (err, _) ->
        fprintf p "ExprError @[%a@]"
        (print_option print_string) err
  | Expr.EHeaderStack (fs, el, i, _) ->
        fprintf p "EHeaderStack <%a>[%a] @[%a@]"
        (print_fields print_string print_type) fs
        print_bigint i
        (print_list ~sep:"," (print_expr)) el 
  | Expr.EHeaderStackAccess (fs, e, i, _) ->
        fprintf p "EHeaderStackAcces <%a> @[%a.@[%a@] @]"
        (print_fields print_string print_type) fs
        (print_expr) e
        print_bigint i


let print_args p (a : 'a Expr.args) = 
  (print_fields print_string (print_paramarg print_expr print_expr)) p a
let print_arrowE p (a : 'a Expr.arrowE) = 
  (print_arrow print_string print_expr print_expr print_expr) p a

let print_constructor_arg p (c: 'a Expr.constructor_arg)=
    match c with 
    | CAExpr e -> fprintf p "CAExpr @[%a@]" print_expr e 
    | CAName s -> fprintf p "CAName @[%a@]" print_string s

let print_constructor_args p (c : 'a Expr.constructor_args) = 
  (print_fields print_string print_constructor_arg) p c

let print_hsop p (h : Stmt.hsop) = 
  match h with 
  | Stmt.HSPush -> fprintf p "HSPush"
  | Stmt.HSPop -> fprintf p "HSPop"

let print_sum print1 print2 p (s: ('a,'b) Poulet4.Datatypes.sum) = 
  match s with 
  | Poulet4.Datatypes.Coq_inl a -> print1 p a
  | Poulet4.Datatypes.Coq_inr b -> print2 p b

let rec print_stmt p (s: 'a Stmt.s) =
  match s with
  | Stmt.SSkip (_) -> fprintf p "SSkip"
  | Stmt.SVardecl (s, sum, _) -> 
    fprintf p "SVardecl @[Name: %a@] @[Init: %a@])"
    print_string s
    (print_sum print_type print_expr) sum
  | Stmt.SAssign (e1, e2, _) ->
    fprintf p "SAssign @[%a := %a@]"
    print_expr e1
    print_expr e2
  | Stmt.SConditional (e,s1,s2,_) ->
    fprintf p "SConditional @[if (%a) then (%a) else (%a)@]" 
    print_expr e
    print_stmt s1
    print_stmt s2
  | Stmt.SSeq (s1,s2,_) -> 
    fprintf p "SSeq @[%a \n %a@]"
    print_stmt s1 
    print_stmt s2
  | Stmt.SBlock (s) -> 
    fprintf p "SBlock %a"
    print_stmt s
  | Stmt.SExternMethodCall (name, meth, tl, arr, _) ->
    fprintf p "SExternMethodCall %s.%s <%a>(%a)"
    name 
    meth
    ((print_list ~sep:"," print_type)) tl
    print_arrowE arr
  
  | Stmt.SFunCall (s, tl, arr, _) ->
    fprintf p "SFunCall %s<%a>(%a) "
    s
    ((print_list ~sep:"," print_type)) tl
    print_arrowE arr
  
  | Stmt.SActCall (s, args, _) ->
    fprintf p "SActCall %s(%a)"
    s
    print_args args

  | Stmt.SReturn (eo, _) ->
    fprintf p "SReturn %a"
    (print_option print_expr) eo

  | Stmt.SExit _ ->
    fprintf p "SExit"

  | Stmt.SInvoke (s, _) ->
    fprintf p "SInvoke %s" s  

  | Stmt.SApply (s, fs, arg, _) ->
    fprintf p "SApply @[%s, Ext_args = %a, args = %a@]"
    s
    print_string_string_fields fs
    print_args arg

  | Stmt.SHeaderStackOp (s, t, h, i, _) ->
    fprintf p "SHeaderStackOp %s<%a>.%a(%a)"
    s
    print_type t
    print_hsop h 
    print_bigint i

  | Stmt.SSetValidity (hdr, valid, _) ->
    fprintf p "SSetValidity %a := %a"
    print_expr hdr
    print_bool valid
 

let print_parser_state p (s: Parser.state) = 
  match s with 
  | Parser.STStart -> fprintf p "%s" "(STStart)"
  | Parser.STAccept -> fprintf p "%s" "(STAccept)"
  | Parser.STReject -> fprintf p "%s" "(STReject)"
  | Parser.STName (name) -> fprintf p "(STName %s)" name

let rec print_pat p (pat: Parser.pat) = 
  match pat with
  | Parser.PATWild -> fprintf p "PATWild"
  | Parser.PATMask (p1,p2) -> 
      fprintf p "PATMask(%a, %a)"
      print_pat p1
      print_pat p2
  | Parser.PATRange (p1,p2) ->
      fprintf p "PATRange(%a, %a)"
      print_pat p1
      print_pat p2
  | Parser.PATBit (w,v) ->
      fprintf p "PATBit<%a> (%a)"
      print_bigint w
      print_bigint v
  | Parser.PATInt (w,v) ->
      fprintf p "PATInt<%a> (%a)"
      print_bigint w
      print_bigint v
  | Parser.PATTuple (pl) ->
      fprintf p "PATTuple@[%a@]"
      (print_list print_pat) pl


let rec print_parser_expr p (e: 'a Parser.e) = 
  match e with 
  | Parser.PGoto (s,_) -> fprintf p "PGoto (%a)" print_parser_state s
  | Parser.PSelect (e, pe, fs, _) -> 
    fprintf p "PSelect (discriminate := %a, default := %a, cases = %a) "
    print_expr e
    print_parser_expr pe
    (print_fields print_pat print_parser_expr) fs

let print_parser_state_block p (st: 'a Parser.state_block) = 
  fprintf p "(Stateblock \n 
              (stmt %a) \n
              (trans %a) \n
              )"
  print_stmt st.stmt 
  print_parser_expr st.trans

let print_table p (t: 'tags_t Control.table) =
  fprintf p "(Table \n
             (table_key %a)
             (table_actions %a))"
  (print_list 
    (fun p (a,b) -> fprintf p "%a<%a>" 
     print_expr a 
     print_matchkind b)
    ) t.table_key
  
  (print_list print_string) t.table_actions

let rec print_control_d p (d : 'tags_t Control.d) =
  match d with 
  | Control.CDAction (s, pa, st, _) ->
    fprintf p "CDAction %s(%a){%a}"
    s
    print_params pa
    print_stmt st 
  | Control.CDTable (s, t, _) ->
    fprintf p "CDTable %s (%a)"
    s
    print_table t
  | Control.CDSeq (d1,d2,_) ->
    fprintf p "CDSeq (%a \n %a)"
    print_control_d d1
    print_control_d d2 

let rec print_tp_decl p (d: 'a TopDecl.d) = 
  match d with 
  | TopDecl.TPInstantiate (constructor_name, instance_name, type_args, cargs,_) ->
    fprintf p "@[TPInstantiate \n (constructor_name = %a) \n (instance_name = %a)
    \n (type_args = %a) \n (cargs = %a) @]"
    print_string constructor_name
    print_string instance_name
    (print_list print_type) type_args
    print_constructor_args cargs

  | TopDecl.TPExtern (extern_name, type_params, cparams, methods, _) -> 
    fprintf p "@[TPExtern \n (extern_name = %a) \n (type_params = %a) \n
    (cparams = %a) \n (methods = %a) @]" 
    print_string extern_name
    (print_list print_string) type_params
    print_constructor_params cparams
    (print_fields print_string 
      (fun p (a,b) ->
      fprintf p "%a<%a>"
        (print_list ~sep:"," print_string) a
        print_arrowT b
      )
    ) methods

  | TopDecl.TPControl (control_name, cparams, eparams, params, body, apply_blk, _) ->
    fprintf p "@[TPControl \n (control_name = %a) \n (cparams = %a) \n (eparams = %a)
              \n (params = %a) \n (body = %a) \n (apply_blk = %a)@] "
    print_string control_name
    print_constructor_params cparams
    print_string_string_fields eparams
    print_params params
    print_control_d body 
    print_stmt apply_blk

  | TopDecl.TPParser (name, constructors, fields, params, state, states,_) ->
    fprintf p "@[TPParser \n (name = %a) \n (cparams = %a) \n (eparams = %a)
              \n (params = %a) \n (start = %a) \n (states = %a)@] "
    print_string name
    print_constructor_params constructors
    print_string_string_fields fields
    print_params params
    print_parser_state_block state
    (print_fields print_string print_parser_state_block) states
  
  | TopDecl.TPFunction (function_name, type_params, signature, body, _) ->
    fprintf p "@[TPFunction \n (function_name = %a) \n (type_params = %a) \n
      (signature = %a) \n (body = %a) @]"
    print_string function_name
    (print_list ~sep:"," print_string) type_params
    print_arrowT signature
    print_stmt body

  | TopDecl.TPSeq (d1,d2,_) ->
    fprintf p "@[TPSeq \n %a \n %a @]"
    print_tp_decl d1 
    print_tp_decl d2