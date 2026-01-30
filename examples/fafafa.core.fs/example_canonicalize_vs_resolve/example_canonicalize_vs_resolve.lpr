{$CODEPAGE UTF8}
program example_canonicalize_vs_resolve;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.fs.path;

procedure Demo;
var P, R, REx, C1, C2: string;
begin
  P := 'example.tmp';
  R := ResolvePath(P);
  REx := ResolvePathEx(P, True, False);
  C1 := Canonicalize(P, True);
  C2 := Canonicalize(P, False);
  Writeln('Input    : ', P);
  Writeln('Resolve  : ', R);
  Writeln('ResolveEx: ', REx);
  Writeln('Canon(F) : ', C1);
  Writeln('Canon(NF): ', C2);
end;

begin
  try
    Demo;
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

