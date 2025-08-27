unit fafafa.core.json.noexcept;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json,
  fafafa.core.json.errors;



type
  // 返回 0 表示成功，非 0 为错误（映射自 TJsonErrorCode）
  TJsonReaderNoExcept = record
    Reader: IJsonReader;
    class function New(AAllocator: TAllocator = nil): TJsonReaderNoExcept; static;
    // 不抛异常，返回错误码；成功时返回 0 并填充 Doc
    function ReadFromString(const AJson: String; out Doc: IJsonDocument; AFlags: TJsonReadFlags = []): Integer;
    function ReadFromStringN(const AJson: PChar; ALength: SizeUInt; out Doc: IJsonDocument; AFlags: TJsonReadFlags = []): Integer;
    // 带错误信息的重载：返回错误码并输出错误详情
    function ReadFromString(const AJson: String; out Doc: IJsonDocument; out Err: TJsonError; AFlags: TJsonReadFlags = []): Integer;
    function ReadFromStringN(const AJson: PChar; ALength: SizeUInt; out Doc: IJsonDocument; out Err: TJsonError; AFlags: TJsonReadFlags = []): Integer;
  end;

  TJsonWriterNoExcept = record
    class function WriteToString(ADocument: IJsonDocument; out S: String; AFlags: TJsonWriteFlags = []): Integer; static;
  end;

// 错误码映射（如未来需要更统一的整型码，可在此集中转换）
function ToUnifiedJsonErrorCode(ACode: TJsonErrorCode): Integer;

implementation

function ToUnifiedJsonErrorCode(ACode: TJsonErrorCode): Integer;
begin
  // 目前直接使用 Ord(ACode)；预留统一层
  Result := Ord(ACode);
end;

class function TJsonReaderNoExcept.New(AAllocator: TAllocator): TJsonReaderNoExcept;
begin
  Result.Reader := NewJsonReader(AAllocator);
end;

function TJsonReaderNoExcept.ReadFromString(const AJson: String; out Doc: IJsonDocument; AFlags: TJsonReadFlags): Integer;
begin
  try
    Doc := Reader.ReadFromString(AJson, AFlags);
    Exit(0);
  except
    on E: EJsonParseError do
      Exit(ToUnifiedJsonErrorCode(E.Code));
    on E: Exception do
      Exit(Ord(jecInvalidParameter));
  end;
end;

function TJsonReaderNoExcept.ReadFromStringN(const AJson: PChar; ALength: SizeUInt; out Doc: IJsonDocument; AFlags: TJsonReadFlags): Integer;
begin
  try
    Doc := Reader.ReadFromStringN(AJson, ALength, AFlags);
    Exit(0);
  except
    on E: EJsonParseError do
      Exit(ToUnifiedJsonErrorCode(E.Code));
    on E: Exception do
      Exit(Ord(jecInvalidParameter));
  end;
end;

function TJsonReaderNoExcept.ReadFromString(const AJson: String; out Doc: IJsonDocument; out Err: TJsonError; AFlags: TJsonReadFlags): Integer;
begin
  Err.Code := jecSuccess; Err.Message := ''; Err.Position := 0;
  try
    Doc := Reader.ReadFromString(AJson, AFlags);
    Exit(0);
  except
    on E: EJsonParseError do
    begin
      Err.Code := E.Code; Err.Position := E.Position;
      if (E.Message <> '') then Err.Message := E.Message
      else Err.Message := JsonFormatErrorMessage(Err, True);
      Exit(ToUnifiedJsonErrorCode(E.Code));
    end;
    on E: Exception do
    begin
      Err.Code := jecInvalidParameter; Err.Position := 0;
      if (E.Message <> '') then Err.Message := E.Message
      else Err.Message := JsonDefaultMessageFor(jecInvalidParameter);
      Exit(Ord(jecInvalidParameter));
    end;
  end;
end;

function TJsonReaderNoExcept.ReadFromStringN(const AJson: PChar; ALength: SizeUInt; out Doc: IJsonDocument; out Err: TJsonError; AFlags: TJsonReadFlags): Integer;
begin
  Err.Code := jecSuccess; Err.Message := ''; Err.Position := 0;
  try
    Doc := Reader.ReadFromStringN(AJson, ALength, AFlags);
    Exit(0);
  except
    on E: EJsonParseError do
    begin
      Err.Code := E.Code; Err.Position := E.Position;
      if (E.Message <> '') then Err.Message := E.Message
      else Err.Message := JsonFormatErrorMessage(Err, True);
      Exit(ToUnifiedJsonErrorCode(E.Code));
    end;
    on E: Exception do
    begin
      Err.Code := jecInvalidParameter; Err.Position := 0;
      if (E.Message <> '') then Err.Message := E.Message
      else Err.Message := JsonDefaultMessageFor(jecInvalidParameter);
      Exit(Ord(jecInvalidParameter));
    end;
  end;
end;

class function TJsonWriterNoExcept.WriteToString(ADocument: IJsonDocument; out S: String; AFlags: TJsonWriteFlags): Integer;
begin
  try
    if ADocument = nil then
    begin
      S := '';
      Exit(Ord(jecInvalidParameter));
    end;
    S := NewJsonWriter.WriteToString(ADocument, AFlags);
    Exit(0);
  except
    on E: EJsonParseError do
      Exit(ToUnifiedJsonErrorCode(E.Code));
    on E: Exception do
      Exit(Ord(jecInvalidParameter));
  end;
end;

end.

