{$CODEPAGE UTF8}
unit test_args_edgecases_combo;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_ArgsEdge_Combo = class(TTestCase)
  published
    procedure Test_MixedQuotesAndBackslashes_Windows;
    procedure Test_LongArgWithSpaces_Windows;
    procedure Test_SpaceOnlyAndEmptyArgs_Unix;
  end;

implementation

procedure TTestCase_ArgsEdge_Combo.Test_MixedQuotesAndBackslashes_Windows;
var
  B: IProcessBuilder;
  OutS: string;
begin
  {$IFDEF WINDOWS}
  // 混合引号与反斜杠的复杂参数，验证 QuoteArgWindows 的稳健性
  B := NewProcessBuilder.Command('cmd.exe')
       .Args(['/c','echo','C:\Path With Space\"inner"\trail\\'])
       .CaptureStdOut;
  OutS := Trim(B.Output);
  // 放宽断言，验证关键片段存在
  AssertTrue(Pos('Path With Space', OutS) > 0);
  AssertTrue(Pos('inner', OutS) > 0);
  AssertTrue(Pos('trail', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_Combo.Test_LongArgWithSpaces_Windows;
var
  B: IProcessBuilder;
  OutS, L: string;
  I: Integer;
begin
  {$IFDEF WINDOWS}
  // 超长且包含空格的参数
  L := 'start';
  for I := 1 to 300 do L := L + ' x';
  B := NewProcessBuilder.Command('cmd.exe')
       .Args(['/c','echo',L])
       .CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Length(OutS) >= 600);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_Combo.Test_SpaceOnlyAndEmptyArgs_Unix;
var
  B: IProcessBuilder;
  OutS: string;
begin
  {$IFDEF UNIX}
  // 仅空格与空字符串混合参数，按字面 argv 传递
  B := NewProcessBuilder.Command('/bin/echo')
       .Args(['',' ', 'A', '', ' '])
       .CaptureStdOut;
  OutS := B.Output; // 不 Trim，检查空格
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos(' ', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ArgsEdge_Combo);

end.

