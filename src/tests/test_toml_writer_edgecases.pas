unit test_toml_writer_edgecases;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterEdgecaseTests;

implementation

type
  TTomlWriterEdgeCaseCase = class(TTestCase)
  private
    function NormalizeEOL(const S: String): String;
  published
    procedure Test_Quoted_Keys_Pretty_Sorted_Spaced;
    procedure Test_Pretty_BlankLines_With_AoT;
    procedure Test_Datetime_Roundtrip_Mixed_With_Scalars;
  end;

function TTomlWriterEdgeCaseCase.NormalizeEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterEdgeCaseCase.Test_Quoted_Keys_Pretty_Sorted_Spaced;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  // 带空格与破折号的键名，Writer 应加引号
  B.BeginTable('root').PutStr('title','TOML Test').EndTable;
  B.BeginTable('root.sub table').
    PutInt('a-b', 1).
    PutFloat('f', 2.5).
    PutBool('x y', True).
  EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  // 快照：表头中包含引号以容纳空格；键名包含引号以容纳空格与非 bare 字符
  Exp := '[root]'+LE+'title = "TOML Test"'
      + LE+LE+'[root."sub table"]'+LE+'a-b = 1'+LE+'f = 2.5'+LE+'"x y" = true';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure TTomlWriterEdgeCaseCase.Test_Pretty_BlankLines_With_AoT;
var
  B: ITomlBuilder; D: ITomlDocument; S, Exp, LE: String;
begin
  LE := LineEnding;
  B := NewDoc;
  B.BeginTable('app').PutStr('name','core').EndTable;
  // 构造 AoT 并附带标量，验证 Pretty 在 [[...]] 前有空行
  B.EnsureArray('app.items');
  B.PushTable('app.items').PutInt('id', 1).EndTable;
  B.PushTable('app.items').PutInt('id', 2).EndTable;
  D := B.Build;
  S := String(ToToml(D, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[app]'+LE+'name = "core"'
      + LE+LE+'[[app.items]]'+LE+'id = 1'
      + LE+LE+'[[app.items]]'+LE+'id = 2';
  AssertEquals(NormalizeEOL(Exp), NormalizeEOL(S));
end;

procedure TTomlWriterEdgeCaseCase.Test_Datetime_Roundtrip_Mixed_With_Scalars;
var
  Doc: ITomlDocument; Err: TTomlError; OutS: String; Txt: RawByteString;
begin
  // 混合标量与日期时间，验证 roundtrip 输出包含原始时间文本
  Txt := '[cfg]'+LineEnding+
         'name = "x"'+LineEnding+
         'tsZ = 1979-05-27T07:32:00Z'+LineEnding+
         'tsO = 1979-05-27T07:32:00+07:00'+LineEnding+
         'ldt = 1979-05-27T07:32:00';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  OutS := String(ToToml(Doc, [twfPretty, twfSortKeys]));
  AssertTrue(Pos('[cfg]', OutS) > 0);
  AssertTrue(Pos('name="x"', OutS) > 0);
  AssertTrue(Pos('1979-05-27T07:32:00Z', OutS) > 0);
  AssertTrue(Pos('1979-05-27T07:32:00+07:00', OutS) > 0);
  AssertTrue(Pos('1979-05-27T07:32:00', OutS) > 0);
end;

procedure RegisterTomlWriterEdgecaseTests;
begin
  RegisterTest('toml-writer-edgecases', TTomlWriterEdgeCaseCase);
end;

end.

