Require Import Coq.Lists.List.
Require Import Coq.Strings.String.

From Coq Require Import Numbers.BinNums Classes.EquivDec.

From Poulet4.P4light.Syntax Require P4String P4Int.


Section Syntax.

  Context {tags_t: Type}.
  Notation P4String := (P4String.t tags_t).
  Notation P4Int := (P4Int.t tags_t).

  Variant parameter :=
  | Parameter (direction: direction)
              (typ: surfaceTyp)
              (default_value: option expression)
              (variable: P4String).

  Variant direction :=
  | In
  | Out
  | InOut
  | Directionless.

  Variant functionKind :=
  | FunParser
  | FunControl
  | FunExtern
  | FunTable
  | FunAction
  | FunFunction
  | FunBuiltin.

  Inductive surfaceTyp := 
  | TypBool
  | TypError
  | TypMatchKind
  | TypInteger
  | TypString
  | TypInt (width: N)
  | TypBit (width: N)
  | TypVarBit (width: N)
  | TypIdentifier (name: P4String)
  | TypSpecialization (base: surfaceTyp)
                   (args: list surfaceType)
  | TypHeaderStack (typ: surfaceTyp)
                   (size: N)
  | TypTuple (types: list surfaceTyp).

  Variant variableTyp :=
  | TypVariable (variable: P4String).

  Variant functionTyp :=
  | TypSurface (typ: surfaceTyp)
  | TypVoid
  | TypVar (variable: variableTyp).

  Inductive declaredTyp :=
  | TypHeader (type_params: list variableTyp)
              (fields: P4String.AList tags_t surfaceTyp)
  | TypHeaderUnion (type_params: list variableTyp)
                   (fields: P4String.AList tags_t surfaceTyp)
  | TypStruct (type_params: list variableTyp)
              (fields: P4String.AList tags_t surfaceTyp)
  | TypEnum (name: P4String)
            (typ: option surfaceTyp)
            (members: list P4String)
  | TypParser (type_params: list variableTyp)
              (parameters: list parameter)
  | TypControl (type_params: list variableTyp)
               (parameters: list parameter)
  | TypPackage (type_params: list variableTyp)
               (wildcard_params: list P4String)
               (parameters: list parameter).

  Inductive synthesizedTyp :=
  | TypFunction (type_params: list variableTyp)
                (parameters: list parameter)
                (kind: functionKind)
                (ret: functionTyp)
  | TypSet (typ: surfaceTyp)
  | TypExtern (extern_name: P4String)
  | TypRecord (type_params: list variableTyp)
              (fields: P4String.AList tags_t surfaceTyp)
  | TypNewTyp (name: P4String)
              (typ: surfaceTyp)
  | TypAction (data_params: list parameter)
              (ctrl_params: list parameter)
  | TypConstructor (type_params: list variableTyp)
                   (wildcard_params: list P4String)
                   (params: list parameter)
                   (ret: functionTyp)
  | TypTable (result_typ_name: P4String).

  Inductive typ :=
  | TypSurface (typ: surfaceTyp)
  | TypDeclared (typ: declaredTyp) 
  | TypSynthesized (typ: synthesizedTyp).
  (* | TypVoid. *)

  Inductive Expression :=
  | ExpBool (b: Bool)
  | ExpString (s: P4String)
  | ExpInt (i: P4Int)
  | ExpSignedInt ().

End Syntax. 
