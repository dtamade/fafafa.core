{$CODEPAGE UTF8}
unit Test_fafafa_core_json_encoding_flags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json, fafafa.core.json.types, fafafa.core.json.core;

type
  TTestCase_Json_Encoding_Flags = class(TTestCase)
  published
    procedure Test_ReadFromString_WithBom_Allowed_Parses;
    procedure Test_ReadFromString_WithBom_Disallowed_Err;
    procedure Test_ReadFromFile_Empty_Returns_EmptyError;
  end;

implementation

procedure TTestCase_Json_Encoding_Flags.Test_ReadFromString_WithBom_Allowed_Parses;
var Reader: IJsonReader; Doc: IJsonDocument; S: RawByteString;
begin
  Reader := CreateJsonReader(GetRtlAllocator);
  // UTF-8 BOM + {}
  S := #$EF#$BB#$BF + RawByteString('{}');
  Doc := Reader.ReadFromStringN(PChar(Pointer(S)), Length(S), [jrfAllowBOM]);
  AssertTrue(Assigned(Doc));
  AssertTrue(Assigned(Doc.Root));
  AssertTrue(Doc.Root.IsObject);
end;

procedure TTestCase_Json_Encoding_Flags.Test_ReadFromString_WithBom_Disallowed_Err;
var Reader: IJsonReader; S: RawByteString;
begin
  Reader := CreateJsonReader(GetRtlAllocator);
  S := #$EF#$BB#$BF + RawByteString('{}');
  try
    Reader.ReadFromStringN(PChar(Pointer(S)), Length(S), []);
    Fail('Expected EJsonParseError for disallowed BOM');
  except
    on E: EJsonParseError do
    begin
      // Code 应为 jecUnexpectedCharacter，具体消息不强依赖
      AssertTrue(E.Code <> jecSuccess);
    end;
  end;
end;

procedure TTestCase_Json_Encoding_Flags.Test_ReadFromFile_Empty_Returns_EmptyError;
var Reader: IJsonReader; FN: String; F: TFileStream;
begin
  Reader := CreateJsonReader(GetRtlAllocator);
  FN := 'tmp_empty_json_test.json';
  // 创建空文件
  F := TFileStream.Create(FN, fmCreate);
  F.Free;
  try
    try
      Reader.ReadFromFile(FN, []);
      Fail('Expected EJsonParseError for empty file');
    except
      on E: EJsonParseError do
      begin
        AssertTrue(E.Code = jecEmptyContent);
      end;
    end;
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Encoding_Flags);
end.

