program example_csv_basic;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils, fafafa.core.csv;

var
  D: TCSVDialect;
begin
  try
    D := DefaultRFC4180;
    WriteLn('fafafa.core.csv example bootstrap.');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

