{$CODEPAGE UTF8}
program debug_escape;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fafafa.core.csv;

var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  FS: TFileStream;
  B: TBytes;
  I, J: Integer;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  // D.Escape := '\'; // backslash escape as WideChar

  WriteLn('Dialect settings:');
  WriteLn('  Escape: ', Ord(D.Escape));
  WriteLn('  Quote: ', Ord(D.Quote));
  WriteLn;

  TmpFile := 'debug_escape.csv';
  if FileExists(TmpFile) then DeleteFile(TmpFile);

  // Write bytes directly to avoid automatic escaping
  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    B := BytesOf('"line1' + #10 + 'line2",z'); // embedded newline
    FS.WriteBuffer(B[0], Length(B));
  finally
    FS.Free;
  end;

  WriteLn('Input file content:');
  for I := 0 to High(B) do
    Write(Chr(B[I]));
  WriteLn;
  
  WriteLn('Byte values:');
  for I := 0 to High(B) do
    Write(B[I], ' ');
  WriteLn;

  try
    R := OpenCSVReader(TmpFile, D);
    if R.ReadNext(Rec) then
    begin
      WriteLn('Field count: ', Rec.Count);
      for I := 0 to Rec.Count - 1 do
      begin
        WriteLn('Field[', I, '] = "', Rec.Field(I), '"');
        Write('  Bytes: ');
        for J := 1 to Length(Rec.Field(I)) do
          Write(Ord(Rec.Field(I)[J]), ' ');
        WriteLn;
      end;

      // Test comparison
      WriteLn;
      WriteLn('Expected: "line1\nline2"');
      Write('Expected bytes: ');
      for J := 1 to Length('line1' + #10 + 'line2') do
        Write(Ord(('line1' + #10 + 'line2')[J]), ' ');
      WriteLn;
      WriteLn('Actual == Expected: ', Rec.Field(0) = ('line1' + #10 + 'line2'));
    end
    else
      WriteLn('No record read');
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end.
