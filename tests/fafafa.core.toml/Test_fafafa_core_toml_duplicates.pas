{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_duplicates;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Duplicates = class(TTestCase)
  published
    procedure Test_Duplicate_Key_On_Same_Table; inline;
  end;

implementation

procedure TTestCase_Duplicates.Test_Duplicate_Key_On_Same_Table;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  // 同一表内重复键，当前策略：报错（数组表例外留待后续）
  AssertFalse(Parse(RawByteString('a = 1
a = 2'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

initialization
  RegisterTest(TTestCase_Duplicates);
end.

