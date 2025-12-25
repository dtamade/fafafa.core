{
  fafafa.core.id.json — JSON serialization support for ID types

  提供 UUID、ULID、KSUID、Snowflake 等 ID 类型的 JSON 序列化支持:
  - 标准字符串格式序列化
  - 结构化对象格式 (含元数据)
  - 批量序列化支持
  - 自定义格式选项

  JSON 格式示例:
    字符串: "550e8400-e29b-41d4-a716-446655440000"
    对象:   {"uuid": "550e8400-e29b-41d4-a716-446655440000", "version": 4}
}

unit fafafa.core.id.json;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpjson, jsonparser,
  fafafa.core.id,
  fafafa.core.id.ulid,
  fafafa.core.id.ksuid,
  fafafa.core.id.snowflake,
  fafafa.core.id.batch;

type
  { JSON 序列化格式选项 }
  TIdJsonFormat = (
    ijfString,      // 纯字符串: "550e8400-..."
    ijfObject,      // 对象含元数据: {"id": "...", "version": 4}
    ijfBase64Url,   // Base64URL 编码
    ijfBinary       // 二进制数组: [85, 14, ...]
  );

  { UUID JSON 工具 }
  TUuidJson = class
  public
    { 序列化 }
    class function ToJson(const U: TUuid128; Format: TIdJsonFormat = ijfString): string;
    class function ToJsonObject(const U: TUuid128): TJSONObject;
    class function ArrayToJson(const Arr: array of TUuid128): string;

    { 反序列化 }
    class function FromJson(const Json: string): TUuid128;
    class function FromJsonObject(Obj: TJSONObject): TUuid128;
    class function ArrayFromJson(const Json: string): TUuid128Array;

    { TryParse }
    class function TryFromJson(const Json: string; out U: TUuid128): Boolean;
  end;

  { ULID JSON 工具 }
  TUlidJson = class
  public
    class function ToJson(const U: TUlid128; Format: TIdJsonFormat = ijfString): string;
    class function ToJsonObject(const U: TUlid128): TJSONObject;
    class function ArrayToJson(const Arr: array of TUlid128): string;

    class function FromJson(const Json: string): TUlid128;
    class function FromJsonObject(Obj: TJSONObject): TUlid128;
    class function ArrayFromJson(const Json: string): TUlid128Array;

    class function TryFromJson(const Json: string; out U: TUlid128): Boolean;
  end;

  { KSUID JSON 工具 }
  TKsuidJson = class
  public
    class function ToJson(const K: TKsuid160; Format: TIdJsonFormat = ijfString): string;
    class function ToJsonObject(const K: TKsuid160): TJSONObject;
    class function ArrayToJson(const Arr: array of TKsuid160): string;

    class function FromJson(const Json: string): TKsuid160;
    class function FromJsonObject(Obj: TJSONObject): TKsuid160;
    class function ArrayFromJson(const Json: string): TKsuid160Array;

    class function TryFromJson(const Json: string; out K: TKsuid160): Boolean;
  end;

  { Snowflake JSON 工具 }
  TSnowflakeJson = class
  public
    class function ToJson(ID: TSnowflakeID; Format: TIdJsonFormat = ijfString): string;
    class function ToJsonObject(ID: TSnowflakeID; EpochMs: Int64 = 0): TJSONObject;
    class function ArrayToJson(const Arr: array of TSnowflakeID): string;

    class function FromJson(const Json: string): TSnowflakeID;
    class function FromJsonObject(Obj: TJSONObject): TSnowflakeID;
    class function ArrayFromJson(const Json: string): TSnowflakeIDArray;

    class function TryFromJson(const Json: string; out ID: TSnowflakeID): Boolean;
  end;

  { 通用 ID JSON 工具 }
  TIdJson = class
  public
    { 自动检测 ID 类型并序列化 }
    class function Detect(const S: string): string;  // 返回类型名称
  end;

implementation

uses
  DateUtils;

{ Helper functions }

function ParseUuid(const S: string): TUuid128;
begin
  if not TryParseUuid(S, Result) then
    raise Exception.CreateFmt('Invalid UUID: %s', [S]);
end;

function ParseUlid(const S: string): TUlid128;
begin
  if not TryParseUlid(S, Result) then
    raise Exception.CreateFmt('Invalid ULID: %s', [S]);
end;

function ParseKsuid(const S: string): TKsuid160;
begin
  if not TryParseKsuid(S, Result) then
    raise Exception.CreateFmt('Invalid KSUID: %s', [S]);
end;

function BytesToBase64Url(const Data: array of Byte): string;
const
  // ✅ T1.1: 统一常量命名 (B64 → BASE64_URL_CHARS)
  BASE64_URL_CHARS: array[0..63] of Char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
var
  I, Len: Integer;
  Buf: array[0..2] of Byte;
begin
  Result := '';
  Len := Length(Data);
  I := 0;
  while I < Len do
  begin
    Buf[0] := Data[I];
    if I + 1 < Len then Buf[1] := Data[I + 1] else Buf[1] := 0;
    if I + 2 < Len then Buf[2] := Data[I + 2] else Buf[2] := 0;

    Result := Result + BASE64_URL_CHARS[Buf[0] shr 2];
    Result := Result + BASE64_URL_CHARS[((Buf[0] and $03) shl 4) or (Buf[1] shr 4)];
    if I + 1 < Len then
      Result := Result + BASE64_URL_CHARS[((Buf[1] and $0F) shl 2) or (Buf[2] shr 6)];
    if I + 2 < Len then
      Result := Result + BASE64_URL_CHARS[Buf[2] and $3F];

    Inc(I, 3);
  end;
end;

function BytesToJsonArray(const Data: array of Byte): string;
var
  I: Integer;
begin
  Result := '[';
  for I := Low(Data) to High(Data) do
  begin
    if I > Low(Data) then
      Result := Result + ',';
    Result := Result + IntToStr(Data[I]);
  end;
  Result := Result + ']';
end;

{ TUuidJson }

class function TUuidJson.ToJson(const U: TUuid128; Format: TIdJsonFormat): string;
begin
  case Format of
    ijfString:
      Result := '"' + UuidToString(U) + '"';
    ijfObject:
      Result := ToJsonObject(U).AsJSON;
    ijfBase64Url:
      Result := '"' + BytesToBase64Url(U) + '"';
    ijfBinary:
      Result := BytesToJsonArray(U);
    else
      Result := '"' + UuidToString(U) + '"';
  end;
end;

class function TUuidJson.ToJsonObject(const U: TUuid128): TJSONObject;
var
  Version: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('uuid', UuidToString(U));
  Version := (U[6] shr 4) and $0F;
  Result.Add('version', Version);
  Result.Add('variant', 'RFC4122');
end;

class function TUuidJson.ArrayToJson(const Arr: array of TUuid128): string;
var
  JArr: TJSONArray;
  I: Integer;
begin
  JArr := TJSONArray.Create;
  try
    for I := Low(Arr) to High(Arr) do
      JArr.Add(UuidToString(Arr[I]));
    Result := JArr.AsJSON;
  finally
    JArr.Free;
  end;
end;

class function TUuidJson.FromJson(const Json: string): TUuid128;
var
  S: string;
  JData: TJSONData;
begin
  S := Trim(Json);
  if (S <> '') and (S[1] = '"') then
  begin
    // 字符串格式
    S := Copy(S, 2, Length(S) - 2);
    Result := ParseUuid(S);
  end
  else if (S <> '') and (S[1] = '{') then
  begin
    // 对象格式
    JData := GetJSON(S);
    try
      if JData is TJSONObject then
        Result := FromJsonObject(TJSONObject(JData))
      else
        raise Exception.Create('Invalid UUID JSON: expected object');
    finally
      JData.Free;
    end;
  end
  else
    Result := ParseUuid(S);
end;

class function TUuidJson.FromJsonObject(Obj: TJSONObject): TUuid128;
var
  S: string;
begin
  S := Obj.Get('uuid', '');
  if S = '' then
    S := Obj.Get('id', '');
  if S = '' then
    raise Exception.Create('Invalid UUID JSON object: missing uuid/id field');
  Result := ParseUuid(S);
end;

class function TUuidJson.ArrayFromJson(const Json: string): TUuid128Array;
var
  JData: TJSONData;
  JArr: TJSONArray;
  I: Integer;
begin
  JData := GetJSON(Json);
  try
    if not (JData is TJSONArray) then
      raise Exception.Create('Invalid UUID array JSON: expected array');
    JArr := TJSONArray(JData);
    SetLength(Result, JArr.Count);
    for I := 0 to JArr.Count - 1 do
      Result[I] := ParseUuid(JArr.Strings[I]);
  finally
    JData.Free;
  end;
end;

class function TUuidJson.TryFromJson(const Json: string; out U: TUuid128): Boolean;
begin
  try
    U := FromJson(Json);
    Result := True;
  except
    Result := False;
    FillChar(U, SizeOf(U), 0);
  end;
end;

{ TUlidJson }

class function TUlidJson.ToJson(const U: TUlid128; Format: TIdJsonFormat): string;
begin
  case Format of
    ijfString:
      Result := '"' + UlidToString(U) + '"';
    ijfObject:
      Result := ToJsonObject(U).AsJSON;
    ijfBase64Url:
      Result := '"' + BytesToBase64Url(U) + '"';
    ijfBinary:
      Result := BytesToJsonArray(U);
    else
      Result := '"' + UlidToString(U) + '"';
  end;
end;

class function TUlidJson.ToJsonObject(const U: TUlid128): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('ulid', UlidToString(U));
  Result.Add('timestamp_ms', Ulid_TimestampMs(UlidToString(U)));
end;

class function TUlidJson.ArrayToJson(const Arr: array of TUlid128): string;
var
  JArr: TJSONArray;
  I: Integer;
begin
  JArr := TJSONArray.Create;
  try
    for I := Low(Arr) to High(Arr) do
      JArr.Add(UlidToString(Arr[I]));
    Result := JArr.AsJSON;
  finally
    JArr.Free;
  end;
end;

class function TUlidJson.FromJson(const Json: string): TUlid128;
var
  S: string;
  JData: TJSONData;
begin
  S := Trim(Json);
  if (S <> '') and (S[1] = '"') then
  begin
    S := Copy(S, 2, Length(S) - 2);
    Result := ParseUlid(S);
  end
  else if (S <> '') and (S[1] = '{') then
  begin
    JData := GetJSON(S);
    try
      if JData is TJSONObject then
        Result := FromJsonObject(TJSONObject(JData))
      else
        raise Exception.Create('Invalid ULID JSON: expected object');
    finally
      JData.Free;
    end;
  end
  else
    Result := ParseUlid(S);
end;

class function TUlidJson.FromJsonObject(Obj: TJSONObject): TUlid128;
var
  S: string;
begin
  S := Obj.Get('ulid', '');
  if S = '' then
    S := Obj.Get('id', '');
  if S = '' then
    raise Exception.Create('Invalid ULID JSON object: missing ulid/id field');
  Result := ParseUlid(S);
end;

class function TUlidJson.ArrayFromJson(const Json: string): TUlid128Array;
var
  JData: TJSONData;
  JArr: TJSONArray;
  I: Integer;
begin
  JData := GetJSON(Json);
  try
    if not (JData is TJSONArray) then
      raise Exception.Create('Invalid ULID array JSON: expected array');
    JArr := TJSONArray(JData);
    SetLength(Result, JArr.Count);
    for I := 0 to JArr.Count - 1 do
      Result[I] := ParseUlid(JArr.Strings[I]);
  finally
    JData.Free;
  end;
end;

class function TUlidJson.TryFromJson(const Json: string; out U: TUlid128): Boolean;
begin
  try
    U := FromJson(Json);
    Result := True;
  except
    Result := False;
    FillChar(U, SizeOf(U), 0);
  end;
end;

{ TKsuidJson }

class function TKsuidJson.ToJson(const K: TKsuid160; Format: TIdJsonFormat): string;
begin
  case Format of
    ijfString:
      Result := '"' + KsuidToString(K) + '"';
    ijfObject:
      Result := ToJsonObject(K).AsJSON;
    ijfBase64Url:
      Result := '"' + BytesToBase64Url(K) + '"';
    ijfBinary:
      Result := BytesToJsonArray(K);
    else
      Result := '"' + KsuidToString(K) + '"';
  end;
end;

class function TKsuidJson.ToJsonObject(const K: TKsuid160): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('ksuid', KsuidToString(K));
  Result.Add('timestamp', Ksuid_TimestampUnixSeconds(KsuidToString(K)));
end;

class function TKsuidJson.ArrayToJson(const Arr: array of TKsuid160): string;
var
  JArr: TJSONArray;
  I: Integer;
begin
  JArr := TJSONArray.Create;
  try
    for I := Low(Arr) to High(Arr) do
      JArr.Add(KsuidToString(Arr[I]));
    Result := JArr.AsJSON;
  finally
    JArr.Free;
  end;
end;

class function TKsuidJson.FromJson(const Json: string): TKsuid160;
var
  S: string;
  JData: TJSONData;
begin
  S := Trim(Json);
  if (S <> '') and (S[1] = '"') then
  begin
    S := Copy(S, 2, Length(S) - 2);
    Result := ParseKsuid(S);
  end
  else if (S <> '') and (S[1] = '{') then
  begin
    JData := GetJSON(S);
    try
      if JData is TJSONObject then
        Result := FromJsonObject(TJSONObject(JData))
      else
        raise Exception.Create('Invalid KSUID JSON: expected object');
    finally
      JData.Free;
    end;
  end
  else
    Result := ParseKsuid(S);
end;

class function TKsuidJson.FromJsonObject(Obj: TJSONObject): TKsuid160;
var
  S: string;
begin
  S := Obj.Get('ksuid', '');
  if S = '' then
    S := Obj.Get('id', '');
  if S = '' then
    raise Exception.Create('Invalid KSUID JSON object: missing ksuid/id field');
  Result := ParseKsuid(S);
end;

class function TKsuidJson.ArrayFromJson(const Json: string): TKsuid160Array;
var
  JData: TJSONData;
  JArr: TJSONArray;
  I: Integer;
begin
  JData := GetJSON(Json);
  try
    if not (JData is TJSONArray) then
      raise Exception.Create('Invalid KSUID array JSON: expected array');
    JArr := TJSONArray(JData);
    SetLength(Result, JArr.Count);
    for I := 0 to JArr.Count - 1 do
      Result[I] := ParseKsuid(JArr.Strings[I]);
  finally
    JData.Free;
  end;
end;

class function TKsuidJson.TryFromJson(const Json: string; out K: TKsuid160): Boolean;
begin
  try
    K := FromJson(Json);
    Result := True;
  except
    Result := False;
    FillChar(K, SizeOf(K), 0);
  end;
end;

{ TSnowflakeJson }

class function TSnowflakeJson.ToJson(ID: TSnowflakeID; Format: TIdJsonFormat): string;
begin
  case Format of
    ijfString:
      Result := '"' + IntToStr(ID) + '"';
    ijfObject:
      Result := ToJsonObject(ID).AsJSON;
    else
      Result := '"' + IntToStr(ID) + '"';
  end;
end;

class function TSnowflakeJson.ToJsonObject(ID: TSnowflakeID; EpochMs: Int64): TJSONObject;
var
  TimestampMs: Int64;
begin
  Result := TJSONObject.Create;
  Result.Add('id', IntToStr(ID));
  Result.Add('id_int', ID);

  // Extract components (Twitter format)
  TimestampMs := (ID shr 22);
  if EpochMs > 0 then
    TimestampMs := TimestampMs + EpochMs
  else
    TimestampMs := TimestampMs + 1288834974657;  // Twitter epoch

  Result.Add('timestamp_ms', TimestampMs);
  Result.Add('worker_id', (ID shr 12) and $3FF);
  Result.Add('sequence', ID and $FFF);
end;

class function TSnowflakeJson.ArrayToJson(const Arr: array of TSnowflakeID): string;
var
  JArr: TJSONArray;
  I: Integer;
begin
  JArr := TJSONArray.Create;
  try
    for I := Low(Arr) to High(Arr) do
      JArr.Add(IntToStr(Arr[I]));
    Result := JArr.AsJSON;
  finally
    JArr.Free;
  end;
end;

class function TSnowflakeJson.FromJson(const Json: string): TSnowflakeID;
var
  S: string;
  JData: TJSONData;
begin
  S := Trim(Json);
  if (S <> '') and (S[1] = '"') then
  begin
    S := Copy(S, 2, Length(S) - 2);
    Result := StrToInt64(S);
  end
  else if (S <> '') and (S[1] = '{') then
  begin
    JData := GetJSON(S);
    try
      if JData is TJSONObject then
        Result := FromJsonObject(TJSONObject(JData))
      else
        raise Exception.Create('Invalid Snowflake JSON: expected object');
    finally
      JData.Free;
    end;
  end
  else
    Result := StrToInt64(S);
end;

class function TSnowflakeJson.FromJsonObject(Obj: TJSONObject): TSnowflakeID;
var
  S: string;
begin
  // Try id_int first (numeric), then id (string)
  if Obj.Find('id_int') <> nil then
    Result := Obj.Int64s['id_int']
  else
  begin
    S := Obj.Get('id', '');
    if S = '' then
      raise Exception.Create('Invalid Snowflake JSON object: missing id field');
    Result := StrToInt64(S);
  end;
end;

class function TSnowflakeJson.ArrayFromJson(const Json: string): TSnowflakeIDArray;
var
  JData: TJSONData;
  JArr: TJSONArray;
  I: Integer;
begin
  JData := GetJSON(Json);
  try
    if not (JData is TJSONArray) then
      raise Exception.Create('Invalid Snowflake array JSON: expected array');
    JArr := TJSONArray(JData);
    SetLength(Result, JArr.Count);
    for I := 0 to JArr.Count - 1 do
    begin
      if JArr.Items[I].JSONType = jtString then
        Result[I] := StrToInt64(JArr.Strings[I])
      else
        Result[I] := JArr.Int64s[I];
    end;
  finally
    JData.Free;
  end;
end;

class function TSnowflakeJson.TryFromJson(const Json: string; out ID: TSnowflakeID): Boolean;
begin
  try
    ID := FromJson(Json);
    Result := True;
  except
    Result := False;
    ID := 0;
  end;
end;

{ TIdJson }

class function TIdJson.Detect(const S: string): string;
var
  Len: Integer;
begin
  Len := Length(S);

  // UUID: 36 chars with dashes, 32 without
  if (Len = 36) and (S[9] = '-') and (S[14] = '-') and (S[19] = '-') and (S[24] = '-') then
  begin
    Result := 'UUID';
    Exit;
  end;

  // ULID: 26 chars Crockford Base32
  if Len = 26 then
  begin
    Result := 'ULID';
    Exit;
  end;

  // KSUID: 27 chars Base62
  if Len = 27 then
  begin
    Result := 'KSUID';
    Exit;
  end;

  // Snowflake: numeric, typically 18-19 digits
  if (Len >= 15) and (Len <= 20) then
  begin
    try
      StrToInt64(S);
      Result := 'Snowflake';
      Exit;
    except
      // Not a number
    end;
  end;

  Result := 'Unknown';
end;

end.
