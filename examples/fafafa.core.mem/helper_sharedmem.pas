unit helper_sharedmem;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

procedure HelperSharedMemMain;

implementation

uses
  SysUtils, StrUtils, fafafa.core.mem.memoryMap;

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

function HexToBytes(const aHex: string): RawByteString;
var
  LIndex: Integer;
  LCount: Integer;
  LByte: Byte;
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
  LPrefix: string;
begin
  Result := aDefault;
  LPrefix := '--' + aKey + '=';
  for LIndex := 1 to ParamCount do
    if LeftStr(ParamStr(LIndex), Length(LPrefix)) = LPrefix then
      Exit(Copy(ParamStr(LIndex), Length(LPrefix) + 1, MaxInt));
end;

procedure HelperSharedMemMain;
var
  LMode: string;
  LName: string;
  LDataHex: string;
  LData: RawByteString;
  LShared: TSharedMemory;
  LHoldMsStr: string;
  LHoldMs: Integer;
begin
  LMode := GetArgValue('mode');
  LName := GetArgValue('name');
  LDataHex := GetArgValue('data');
  if (LMode = '') or (LName = '') then
  begin
    Writeln('ERR: missing args');
    Exit;
  end;

  {$IFDEF WINDOWS}
  if (Pos('\', LName) = 0) then
    LName := 'Local\' + LName;
  {$ELSE}
  // Unix: 确保以 / 开头
  if (Length(LName) = 0) or (LName[1] <> '/') then
    LName := '/' + LName;
  {$ENDIF}

  if SameText(LMode, 'writer') then
  begin
    LHoldMsStr := GetArgValue('hold');
    if LHoldMsStr <> '' then
      LHoldMs := StrToIntDef(LHoldMsStr, 0)
    else
      LHoldMs := 0;

    LData := HexToBytes(LDataHex);
    LShared := TSharedMemory.Create;
    try
      if not LShared.CreateShared(LName, 4 + Length(LData), mmaReadWrite) then
      begin
        Writeln('ERR: create failed');
        Exit;
      end;
      if not LShared.WriteLPBytes(0, LData) then
      begin
        Writeln('ERR: write failed');
        Exit;
      end;
      if LHoldMs > 0 then Sleep(LHoldMs);
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
        Exit;
      end;
      if not LShared.ReadLPBytes(0, LData) then
      begin
        Writeln('ERR: read failed');
        Exit;
      end;
      Writeln(BytesToHex(LData));
    finally
      LShared.Free;
    end;
  end
  else
  begin
    Writeln('ERR: invalid mode');
    Exit;
  end;
end;

end.
