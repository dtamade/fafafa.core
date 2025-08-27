{$CODEPAGE UTF8}
program debug_long;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fafafa.core.csv;

var
  D: TCSVDialect;
  W: ICSVWriter;
  R: ICSVReader;
  Rec: ICSVRecord;
  S: UnicodeString;
  I: Integer;
  OutFile: string;
  E, A: RawByteString;
  Arg: string;
  FieldBytes: RawByteString;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  OutFile := 'tmp_writer_long_dbg.csv';
  if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  SetLength(S, 100000);
  for I := 1 to Length(S) do S[I] := '你';
  Arg := UTF8Encode(S);
  {$ifdef FPC}
  Writeln('Arg codepage: ', StringCodePage(Arg));
  {$endif}
  Writeln('Arg length (bytes): ', Length(Arg));
  W.WriteRow([Arg, 'end']);
  W.Flush; W.Close;

  R := OpenCSVReader(OutFile, D);
  if not R.ReadNext(Rec) then begin Writeln('read failed'); Halt(1); end;
  E := UTF8Encode(S);
  A := Rec.Field(0);
  Writeln('E len (bytes): ', Length(E));
  Writeln('A len (bytes): ', Length(A));
  {$ifdef FPC}
  Writeln('Field(0) codepage: ', StringCodePage(Rec.Field(0)));
  Writeln('A codepage: ', StringCodePage(A));
  {$endif}
  Writeln('Unicode Length Field(0): ', Length(UnicodeString(Rec.Field(0))));
  Writeln('Unicode Length S: ', Length(S));
  if E <> A then Writeln('Mismatch');
end.
