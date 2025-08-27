{$CODEPAGE UTF8}
program tests_xxhash;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, fpcunit, testregistry, consoletestrunner,
  fafafa.core.crypto.xxhash.testcase,
  fafafa.core.crypto.xxhash64.added,
  fafafa.core.crypto.xxhash.vectors,
  fafafa.core.crypto.xxhash3.vectors;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'tests_xxhash';
    Application.Run;
  finally
    Application.Free;
  end;
end.

