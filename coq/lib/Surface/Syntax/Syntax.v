Require Import Coq.Lists.List.
Require Import Coq.Strings.String.

From Coq Require Import Numbers.BinNums Classes.EquivDec.

From Poulet4.P4light.Syntax Require Import Info.

From Poulet4.P4light.Syntax Require P4String P4Int.


Section Syntax.

  Notation P4String := (P4String.t Info).
  Notation P4Int := (P4Int.t Info).

  Variant name :=
  | BareName      (tags: Info)
                  (name: P4String)
  | QualifiedName (tags: Info)
                  (namespaces: list P4String)
                  (name: P4String).

  Variant direction :=
  | In            (tags: Info)
  | Out           (tags: Info)
  | InOut         (tags: Info)
  | Directionless (tags: Info).

  Variant functionKind :=
  | FunParser   (tags: Info)
  | FunControl  (tags: Info)
  | FunExtern   (tags: Info)
  | FunTable    (tags: Info)
  | FunAction   (tags: Info)
  | FunFunction (tags: Info)
  | FunBuiltin  (tags: Info).

  Variant uniOp : Type :=
  | Not    (tags: Info)
  | BitNot (tags: Info)
  | UMinus (tags: Info).

  Variant binOp : Type :=
  | Plus     (tags: Info)
  | PlusSat  (tags: Info)
  | Minus    (tags: Info)
  | MinusSat (tags: Info)
  | Mul      (tags: Info)
  | Div      (tags: Info)
  | Mod      (tags: Info)
  | Shl      (tags: Info)
  | Shr      (tags: Info)
  | Le       (tags: Info)
  | Ge       (tags: Info)
  | Lt       (tags: Info)
  | Gt       (tags: Info)
  | Eq       (tags: Info)
  | NotEq    (tags: Info)
  | BitAnd   (tags: Info)
  | BitXor   (tags: Info)
  | BitOr    (tags: Info)
  | PlusPlus (tags: Info)
  | And      (tags: Info)
  | Or       (tags: Info).

  Inductive typ :=
  | TypBool           (tags: Info)
  | TypError          (tags: Info)
  | TypMatchKind      (tags: Info)
  | TypInteger        (tags: Info)
  | TypString         (tags: Info)
  | TypInt            (tags: Info)
                      (width: N)
  | TypBit            (tags: Info)
                      (width: N)
  | TypVarBit         (tags: Info)
                      (width: N)
  | TypIdentifier     (tags: Info)
                      (name: P4String)
  | TypSpecialization (tags: Info)
                      (base: typ) (*surface*)
                      (args: list typ) (*type arg*)
  | TypHeaderStack    (tags: Info)
                      (typ: typ) (*surface*)
                      (size: expression)
  | TypTuple          (tags: Info)
                      (types: list typ) (*surface*)
  | TypHeader         (tags: Info)
                      (type_params: list typVarTyp)
                      (fields: P4String.AList Info typ) (*surface*)
  | TypHeaderUnion    (tags: Info)
                      (type_params: list typVarTyp) (*variable type*)
                      (fields: P4String.AList Info typ) (*surface*)
  | TypStruct         (tags: Info)
                      (type_params: list typVarTyp) (*variable type*)
                      (fields: P4String.AList Info typ) (*surface*)
  | TypEnum           (tags: Info)
                      (name: P4String)
                      (typ: option typ) (*surface*)
                      (members: list P4String)
  | TypParser         (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (parameters: list parameter)
  | TypControl        (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (parameters: list parameter)
  | TypPackage        (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (wildcard_params: list P4String)
                      (parameters: list parameter)
  | TypFunction       (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (parameters: list parameter)
                      (kind: functionKind)
                      (ret: typ) (*surface+void+type variable*)
  | TypSet            (tags: Info)
                      (typ: typ) (*surface*)
  | TypExtern         (tags: Info)
                      (extern_name: P4String)
  | TypRecord         (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (fields: P4String.AList Info typ) (*surface*)
  | TypNewTyp         (tags: Info)
                      (name: P4String)
                      (typ: typ) (*surface*)
  | TypAction         (tags: Info)
                      (data_params: list parameter)
                      (ctrl_params: list parameter)
  | TypConstructor    (tags: Info)
                      (type_params: list typVarTyp) (*type variable*)
                      (wildcard_params: list typVarTyp)
                      (params: list parameter)
                      (ret: typ) (*surface+void+type variable*)
  | TypTable          (tags: Info)
                      (result_typ_name: P4String)
  | TypVoid           (tags: Info)
  | TypDontCare       (tags: Info)
  with typVarTyp := (*type variable or their assignment*)
  | TypVarTyp (type_var: P4String)
              (type: option typ)
  with parameter :=
  | Param (dir: direction)
          (typ: typ) (*surface*)
          (default_value: option expression)
          (variable: P4String)
  with expressionPreT :=
  | ExpBool                   (b: bool)
  | ExpString                 (s: P4String)
  | ExpInt                    (i: P4Int)
  | ExpName                   (name: name)
  | ExpArrayAccess            (array: expression)
                              (index: expression)
  | ExpBitStringAccess        (bits: expression)
                              (low: expression)
                              (high: expression)
  | ExpList                   (value: list expression)
  | ExpRecord                 (entries: P4String.AList Info expression)
  | ExpUnaryOp                (op: uniOp)
                              (arg: expression)
  | ExpBinaryOp               (op: binOp)
                              (arg1: expression)
                              (arg2: expression)
  | ExpCast                   (typ: typ) (*surface*)
                              (expr: expression)
  | ExpTypeMember             (typ: P4String)
                              (mem: P4String)
  | ExpErrorMember            (mem: P4String)
  | ExpExpressionMember       (expr: expression)
                              (mem: P4String)
  | ExpTernary                (cond: expression)
                              (tru: expression)
                              (fls: expression)
  | ExpFunctionCall           (func: expression)
                              (type_args: list typ) (*surface*)
                              (args: list argument)
  | ExpAnonymousInstantiation (typ: typ) (*surface*)
                              (args: list argument)
  | ExpBitMask                (expr: expression)
                              (mask: expression)
  | ExpRange                  (low: expression)
                              (high: expression)
  with expression :=
  | MkExpression (tags: Info)
                 (type: option typ)
                 (expr: expressionPreT)
                 (* (dir: direction) *)
  with argument :=
  | ExpArg      (value: expression) 
  | KeyValueArg (key: P4String)
                (value: expression)
  | MissingArg.

  (* Variant fieldType := *)
  (* | FieldType (typ: typ) (*surface*) *)
  (*             (field: P4String). *)

  Variant stmtSwitchLabel :=
  | StmtSwitchLabelDefault (tags: Info)
  | StmtSwitchLabelName    (tags: Info)
                           (label: P4String).

  Variant tableOrParserMatch :=
  | MatchDefault    (tags: Info)
  | MatchDontCare   (tags: Info)
  | MatchExpression (tags: Info)
                    (expr: expression).

  Variant parserCase :=
  | ParserCase (tags: Info)
               (matches: list tableOrParserMatch)
               (next: P4String).

  Variant methodPrototype :=
  | ProtoConstructor    (tags: Info)
                        (name: P4String)
                        (params: list parameter)
  | ProtoAbstractMethod (tags: Info)
                        (ret_type: typ) (*surface*)
                        (name: P4String)
                        (type_params: list typVarTyp)
                        (params: list parameter)
  | ProtoMethod         (tags: Info)
                        (ret_type: typ) (*surfce*)
                        (name: P4String)
                        (type_params: list typVarTyp)
                        (params: list parameter).

  Variant tableKey :=
  | TabKey (tags: Info)
           (key: expression)
           (match_kind: P4String).

  Variant actionRef :=
  | TabActionRef (tags: Info)
                 (name: name) 
                 (args: list argument).

  Variant tableEntry :=
  | TabEntry (tags: Info)
             (matches: list tableOrParserMatch)
             (action: actionRef).

  Variant tableProperty :=
  | TableKey           (tags: Info)
                       (keys: list tableKey)
  | TableActions       (tags: Info)
                       (actions: list actionRef)
  | TableEntries       (tags: Info)
                       (entries: list tableEntry)
  | TableDefaultAction (tags: Info)
                       (action: actionRef)
                       (const: bool)
  | TableCustom        (tags: Info)
                       (name: P4String)
                       (value: expression)
                       (const: bool).

  Inductive stmtSwitchCases :=
  | StmtSwitchCaseAction      (tags: Info)
                              (lable: stmtSwitchLabel)
                              (code: block)
  | StmtSwitchCaseFallThrough (tags: Info)
                              (lable: stmtSwitchLabel)
  with statementPreT := 
  | StmtMethodCall        (func: expression)
                          (type_args: list typ) (*surface*)
                          (args: list argument)
  | StmtAssignment        (lhs: expression)
                          (rhs: expression)
  | StmtDirectApplication (typ: typ) (*surface*)
                          (args: list argument)
  | StmtConditional       (cond: expression)
                          (tru: statement)
                          (fls: option statement)
  | StmtBlock             (block: block)
  | StmtExit
  | StmtEmpty
  | StmtReturn            (expr: option expression)
  | StmtSwitch            (expr: expression)
                          (cases: list stmtSwitchCases)
  | StmtDeclaration       (decl: declaration) (*can only be variable or constant decl.*)
  with statement :=
  | MkStatement (tags: Info)
                (type: option typ)
                (stmt: statementPreT)
  with block :=
  | BlockEmpty (tags: Info)
  | BlockCons  (statement: statement)
               (rest: block)
  with parserTransition :=
  | ParserDirect (tags: Info)
                 (next: P4String)
  | ParserSelect (tags: Info)
                 (exprs: list expression)
                 (cases: list parserCase)
  with parserState :=
  | ParserState (tags: Info)
                (name: P4String)
                (statements: list statement)
                (transistion: parserTransition)
  with declarationPreT :=
  | DeclConstant         (typ: typ) (*surface*)
                         (name: P4String)
                         (value: expression)
  | DeclInstantiation    (typ: typ) (*surface*)
                         (args: list argument)
                         (name: P4String)
                         (init: list declaration)
  | DeclParser           (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
                         (constructor_params: list parameter)
                         (locals: declaration)
                         (states: list parserState)
  | DeclControl          (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
                         (constructor_params: list parameter)
                         (locals: list declaration)
                         (apply: block)
  | DeclFunction         (ret_typ: typ) (*surface+void+type variable*)
                         (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
                         (body: block)
  | DeclExternFunction   (ret_type: typ) (*surface*)
                         (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
  | DeclVariable         (typ: typ) (*surface*)
                         (name: P4String)
                         (init: option expression)
  | DeclValueSet         (typ: typ) (*surface*)
                         (name: P4String)
                         (size: expression)
  | DeclAction           (name: P4String)
                         (data_params: list parameter)
                         (ctrl_params: list parameter)
                         (body: block)
  | DeclTable            (name: P4String)
                         (props: list tableProperty)
  | DeclHeaderTyp        (name: P4String)
                         (fields: P4String.AList Info typ)
  | DeclHeaderUnionTyp   (name: P4String)
                         (fields: P4String.AList Info typ)
  | DeclStructTyp        (name: P4String)
                         (fields: P4String.AList Info typ)
  | DeclError            (members: list P4String)
  | DeclMatchKind        (members: list P4String)
  | DeclEnumTyp          (name: P4String)
                         (members: list P4String)
  | DeclSerializableEnum (typ: typ) (*surface*)
                         (name: P4String)
                         (members: P4String.AList Info expression)
  | DeclControlTyp       (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
  | DeclParserTyp        (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
  | DeclPackageTyp       (name: P4String)
                         (type_params: list typVarTyp)
                         (params: list parameter)
  | DeclExternObject     (name: P4String)
                         (type_params: list typVarTyp)
                         (methods: list methodPrototype)
  | DeclTypeDef          (name: P4String)
                         (typ_or_dcl: (typ + declaration)) (*surface*)
  | DeclNewType          (name: P4String)
                         (typ_or_dcl: (typ + declaration)) (*surface*)
  with declaration :=
  | MkDeclaration (tags: Info)
                  (type: option typ)
                  (decl: declarationPreT).

  Variant program :=
  | Program (decls: list declaration).


End Syntax. 

