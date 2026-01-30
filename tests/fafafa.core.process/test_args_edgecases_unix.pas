{$CODEPAGE UTF8}
unit test_args_edgecases_unix;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_ArgsEdge_Unix = class(TTestCase)
  published
    procedure Test_SpacesAndQuotes;
    procedure Test_EmptyArg;
    procedure Test_Backslash_NotEscape;
  end;

implementation

procedure TTestCase_ArgsEdge_Unix.Test_SpacesAndQuotes;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  // 验证包含空格与引号的参数在 Unix 通过 argv 传递正确（不经 shell）
  B := NewProcessBuilder.Command('/bin/echo').Args(['a b', '"c"', 'd']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('a b', OutS) > 0);
  AssertTrue(Pos('"c"', OutS) > 0);
  AssertTrue(Pos('d', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_Unix.Test_EmptyArg;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  // 空参数在 Unix 也应作为空字符串传递
  B := NewProcessBuilder.Command('/bin/echo').Args(['A','', 'B']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos('B', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_Unix.Test_Backslash_NotEscape;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  // 反斜杠在 argv 中按字面传递
  B := NewProcessBuilder.Command('/bin/echo').Args(['a\b']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('a\b', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ArgsEdge_Unix);
end.

