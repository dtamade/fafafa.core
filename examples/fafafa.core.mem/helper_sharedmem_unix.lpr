program helper_sharedmem_unix;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  SysUtils,
  fafafa.core.mem,
  fafafa.core.mem.memoryMap;

function HexToBytes(const s: string): RawByteString;
var
  i, n: Integer;
  b: Byte;
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
begin
  n := Length(s) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    b := (HexVal(s[2*i+1]) shl 4) or HexVal(s[2*i+2]);
    Result[ i + 1 ] := AnsiChar(Chr(b));
  end;
end;

function BytesToHex(const buf: RawByteString): string;
const
  Hex: PChar = '0123456789ABCDEF';
var
  i: Integer;
  b: Byte;
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
  i: Integer;
  param, k: string;
begin
  Result := def;
  k := '--' + key + '=';
  for i := 1 to ParamCount do
  begin
    param := ParamStr(i);
    if LeftStr(param, Length(k)) = k then
    begin
      Result := Copy(param, Length(k)+1, MaxInt);
      Exit;
    end;
  end;
end;

procedure WriteBytes(p: PByte; const buf: RawByteString);
var
  L: UInt32;
begin
  L := Length(buf);
  Move(L, p^, SizeOf(L));
  Inc(p, SizeOf(L));
  if L > 0 then Move(buf[1], p^, L);
end;

function ReadBytes(p: PByte): RawByteString;
var
  L: UInt32;
begin
  Move(p^, L, SizeOf(L));
  Inc(p, SizeOf(L));
  SetLength(Result, L);
  if L > 0 then Move(p^, Result[1], L);
end;

var
  mode, name, datahex: string;
  sh: TSharedMemory;
  data: RawByteString;
  base: PByte;
begin
  try
    mode := GetArgValue('mode');
    name := GetArgValue('name');
    datahex := GetArgValue('data');

    if (mode = '') or (name = '') then
    begin
      Writeln('ERR: missing args');
      Halt(2);
    end;

    if SameText(mode, 'writer') then
    begin
      data := HexToBytes(datahex);
      sh := TSharedMemory.Create;
      try
        if not sh.CreateShared(name, 4 + Length(data), mmaReadWrite) then
        begin
          Writeln('ERR: create failed');
          Halt(3);
        end;
        base := PByte(sh.BaseAddress);
        WriteBytes(base, data);
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
          Halt(4);
        end;
        data := ReadBytes(PByte(sh.BaseAddress));
        Writeln(BytesToHex(data));
      finally
        sh.Free;
      end;
    end
    else
    begin
      Writeln('ERR: invalid mode');
      Halt(5);
    end;

    Halt(0);
  except
    on E: Exception do
    begin
      Writeln('ERR: ', E.Message);
      Halt(1);
    end;
  end;
end.

