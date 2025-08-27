unit helper_sharedmem;

{$mode objfpc}{$H+}

interface

procedure HelperSharedMemMain;

implementation

uses
  SysUtils, StrUtils, fafafa.core.mem.memoryMap;

function HexVal(ch: Char): Integer;
begin
  case ch of
    '0'..'9': Result := Ord(ch) - Ord('0');
    'A'..'F': Result := Ord(ch) - Ord('A') + 10;
    'a'..'f': Result := Ord(ch) - Ord('a') + 10;
  else
    Result := 0;
  end;
end;

function HexToBytes(const s: string): RawByteString;
var
  i, n: Integer; b: Byte;
begin
  n := Length(s) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    b := (HexVal(s[2*i+1]) shl 4) or HexVal(s[2*i+2]);
    Result[i+1] := AnsiChar(Chr(b));
  end;
end;

function BytesToHex(const buf: RawByteString): string;
const
  Hex: PChar = '0123456789ABCDEF';
var
  i: Integer; b: Byte;
begin
  SetLength(Result, Length(buf)*2);
  for i := 1 to Length(buf) do
  begin
    b := Byte(buf[i]);
    Result[2*i-1] := Hex[(b shr 4) and $0F];
    Result[2*i]   := Hex[b and $0F];
  end;
end;

function GetArgValue(const key: string; const def: string = ''): string;
var
  i: Integer; pfx: string;
begin
  Result := def;
  pfx := '--' + key + '=';
  for i := 1 to ParamCount do
    if LeftStr(ParamStr(i), Length(pfx)) = pfx then
      Exit(Copy(ParamStr(i), Length(pfx)+1, MaxInt));
end;

procedure HelperSharedMemMain;
var
  mode, name, datahex: string;
  data: RawByteString;
  sh: TSharedMemory;
  holdmsStr: string;
  holdms: Integer;
begin
  mode := GetArgValue('mode');
  name := GetArgValue('name');
  datahex := GetArgValue('data');
  if (mode = '') or (name = '') then
  begin
    Writeln('ERR: missing args');
    Exit;
  end;

  {$IFDEF WINDOWS}
  if (Pos('\', name) = 0) then
    name := 'Local\' + name;
  {$ELSE}
  // Unix: 确保以 / 开头
  if (Length(name) = 0) or (name[1] <> '/') then
    name := '/' + name;
  {$ENDIF}

  if SameText(mode, 'writer') then
  begin
    holdmsStr := GetArgValue('hold');
    if holdmsStr <> '' then
      holdms := StrToIntDef(holdmsStr, 0)
    else
      holdms := 0;

    data := HexToBytes(datahex);
    sh := TSharedMemory.Create;
    try
      if not sh.CreateShared(name, 4 + Length(data), mmaReadWrite) then
      begin
        Writeln('ERR: create failed');
        Exit;
      end;
      if not sh.WriteLPBytes(0, data) then
      begin
        Writeln('ERR: write failed');
        Exit;
      end;
      if holdms > 0 then Sleep(holdms);
    finally
      sh.Free;
    end;
  end
  else if SameText(mode, 'reader') then
  begin
    sh := TSharedMemory.Create;
    try
      if not sh.OpenShared(name, mmaReadWrite) then
      begin
        Writeln('ERR: open failed');
        Exit;
      end;
      if not sh.ReadLPBytes(0, data) then
      begin
        Writeln('ERR: read failed');
        Exit;
      end;
      Writeln(BytesToHex(data));
    finally
      sh.Free;
    end;
  end
  else
  begin
    Writeln('ERR: invalid mode');
    Exit;
  end;
end;

end.

