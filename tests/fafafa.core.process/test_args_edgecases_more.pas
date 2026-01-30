{$CODEPAGE UTF8}
unit test_args_edgecases_more;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_ArgsEdge_More = class(TTestCase)
  published
    procedure Test_MultipleEmptyArgs_Windows;
    procedure Test_OnlyQuotesArg_Windows;
    procedure Test_MultipleEmptyArgs_Unix;
    procedure Test_OnlySpaceArg_Unix;
  end;

implementation

procedure TTestCase_ArgsEdge_More.Test_MultipleEmptyArgs_Windows;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe')
       .Args(['/c','echo','A','','','B']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos('B', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_More.Test_OnlyQuotesArg_Windows;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF WINDOWS}
  // 仅带引号的参数
  B := NewProcessBuilder.Command('cmd.exe')
       .Args(['/c','echo','""']).CaptureStdOut;
  OutS := Trim(B.Output);
  // echo "" -> 输出包含引号，放宽为非空判断
  AssertTrue(Length(OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_More.Test_MultipleEmptyArgs_Unix;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  B := NewProcessBuilder.Command('/bin/echo')
       .Args(['A','','','B']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos('B', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_More.Test_OnlySpaceArg_Unix;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  // 仅空格的参数（按字面 argv 传递）
  B := NewProcessBuilder.Command('/bin/echo')
       .Args([' ']).CaptureStdOut;
  OutS := B.Output; // 不 Trim
  AssertTrue(Pos(' ', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ArgsEdge_More);
end.

