{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_array_of_tables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Array_Of_Tables = class(TTestCase)
  published
    procedure Test_Array_Of_Tables_Parse_Smoke;
  end;

implementation

procedure TTestCase_Array_Of_Tables.Test_Array_Of_Tables_Parse_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  S: RawByteString;
  Root: ITomlTable;
  V: ITomlValue;
  A: ITomlArray;
  T0, T1: ITomlTable;
  S0, S1: String;
begin
  E.Clear;
  // 两个 products 表实例（标准 [[products]] 两次）
  AssertTrue(Parse(RawByteString('[[products]]' + LineEnding + 'name = "Hammer"' + LineEnding + '[[products]]' + LineEnding + 'name = "Nail"'), D, E));
  AssertFalse(E.HasError);

  Root := D.Root;
  V := Root.GetValue('products');
  AssertTrue(V <> nil);
  // 顶层 products 是数组
  A := V as ITomlArray;
  AssertEquals(2, A.Count);
  // 遍历数组校验每项
  T0 := A.Item(0) as ITomlTable;
  T1 := A.Item(1) as ITomlTable;
  AssertTrue(T0 <> nil);
  AssertTrue(T1 <> nil);
  AssertTrue((T0.GetValue('name') <> nil) and T0.GetValue('name').TryGetString(S0));
  AssertTrue((T1.GetValue('name') <> nil) and T1.GetValue('name').TryGetString(S1));
  AssertEquals('Hammer', S0);
  AssertEquals('Nail', S1);
end;

initialization
  RegisterTest(TTestCase_Array_Of_Tables);
end.

