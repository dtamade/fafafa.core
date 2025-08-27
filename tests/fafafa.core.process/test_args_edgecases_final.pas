{$CODEPAGE UTF8}
unit test_args_edgecases_final;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_ArgsEdge_Final = class(TTestCase)
  published
    procedure Test_ManyEmptyArgs_Windows;
    procedure Test_OnlyQuotesArg_Unix;
  end;

implementation

procedure TTestCase_ArgsEdge_Final.Test_ManyEmptyArgs_Windows;
var B: IProcessBuilder; OutS: string; i: Integer; args: array of string;
begin
  {$IFDEF WINDOWS}
  SetLength(args, 30);
  args[0] := '/c'; args[1] := 'echo'; args[2] := 'A';
  for i := 3 to 27 do args[i] := '';
  args[28] := 'B'; args[29] := 'C';
  B := NewProcessBuilder.Command('cmd.exe').Args(args).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos('B', OutS) > 0);
  AssertTrue(Pos('C', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge_Final.Test_OnlyQuotesArg_Unix;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF UNIX}
  B := NewProcessBuilder.Command('/bin/echo').Args(['""']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Length(OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ArgsEdge_Final);
end.

