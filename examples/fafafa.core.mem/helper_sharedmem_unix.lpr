program helper_sharedmem_unix;

{$IFDEF WINDOWS}{$APPTYPE CONSOLE}{$ENDIF}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils, StrUtils,
  fafafa.core.mem,
  fafafa.core.mem.memoryMap;

function HexToBytes(const aHex: string): RawByteString;
var
  LIndex: Integer;
  LCount: Integer;
  LByte: Byte;
  function HexVal(aCh: Char): Integer;
  begin
    case aCh of
      '0'..'9': Result := Ord(aCh) - Ord('0');
      'A'..'F': Result := Ord(aCh) - Ord('A') + 10;
      'a'..'f': Result := Ord(aCh) - Ord('a') + 10;
    else
      Result := 0;
    end;
  end;
begin
  LCount := Length(aHex) div 2;
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LByte := (HexVal(aHex[2 * LIndex + 1]) shl 4) or HexVal(aHex[2 * LIndex + 2]);
    Result[LIndex + 1] := AnsiChar(Chr(LByte));
  end;
end;

function BytesToHex(const aBuf: RawByteString): string;
const
  Hex: PChar = '0123456789ABCDEF';
var
  LIndex: Integer;
  LByte: Byte;
begin
  SetLength(Result, Length(aBuf) * 2);
  for LIndex := 1 to Length(aBuf) do
  begin
    LByte := Byte(aBuf[LIndex]);
    Result[2 * LIndex - 1] := Hex[(LByte shr 4) and $0F];
    Result[2 * LIndex] := Hex[LByte and $0F];
  end;
end;

function GetArgValue(const aKey: string; const aDefault: string = ''): string;
var
  LIndex: Integer;
  LParam: string;
  LPrefix: string;
begin
  Result := aDefault;
  LPrefix := '--' + aKey + '=';
  for LIndex := 1 to ParamCount do
  begin
    LParam := ParamStr(LIndex);
    if LeftStr(LParam, Length(LPrefix)) = LPrefix then
    begin
      Result := System.Copy(LParam, Length(LPrefix) + 1, MaxInt);
      Exit;
    end;
  end;
end;

var
  LMode: string;
  LName: string;
  LDataHex: string;
  LShared: TSharedMemory;
  LData: RawByteString;
  LHoldMs: Integer;
begin
  try
    LMode := GetArgValue('mode');
    LName := GetArgValue('name');
    LDataHex := GetArgValue('data');
    LHoldMs := StrToIntDef(GetArgValue('hold', '0'), 0);

    if (LMode = '') or (LName = '') then
    begin
      Writeln('ERR: missing args');
      Halt(2);
    end;

    if SameText(LMode, 'writer') then
    begin
      LData := HexToBytes(LDataHex);
      LShared := TSharedMemory.Create;
      try
        if not LShared.CreateShared(LName, SizeOf(UInt32) + Length(LData), mmaReadWrite) then
        begin
          Writeln('ERR: create failed');
          Halt(3);
        end;
        if not LShared.WriteLPBytes(0, LData) then
        begin
          Writeln('ERR: write failed');
          Halt(6);
        end;
        if LHoldMs > 0 then
          Sleep(LHoldMs);
      finally
        LShared.Free;
      end;
    end
    else if SameText(LMode, 'reader') then
    begin
      LShared := TSharedMemory.Create;
      try
        if not LShared.OpenShared(LName, mmaReadWrite) then
        begin
          Writeln('ERR: open failed');
          Halt(4);
        end;
        if not LShared.ReadLPBytes(0, LData) then
        begin
          Writeln('ERR: read failed');
          Halt(7);
        end;
        Writeln(BytesToHex(LData));
      finally
        LShared.Free;
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
