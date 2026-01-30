{$CODEPAGE UTF8}
program example_writefileatomic;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.fs, fafafa.core.fs.highlevel, fafafa.core.fs.path;

procedure DemoAtomicWrite;
var
  Target, Back: string;
  Data, ReadBack: TBytes;
begin
  Target := 'atomic_demo.txt';
  Data := TEncoding.UTF8.GetBytes('hello-atomic');
  WriteFileAtomic(Target, Data);
  ReadBack := ReadBinaryFile(Target);
  Back := TEncoding.UTF8.GetString(ReadBack);
  Writeln('Atomic write ok: ', Back);
end;

procedure DemoCanonicalize;
var P, C: string;
begin
  P := 'atomic_demo.txt';
  C := Canonicalize(P, True);
  Writeln('Canonical path: ', C);
end;

begin
  try
    DemoAtomicWrite;
    DemoCanonicalize;
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

