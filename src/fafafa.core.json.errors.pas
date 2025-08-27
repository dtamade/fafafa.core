unit fafafa.core.json.errors;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.json.core;

// 统一的 JSON 错误消息与常量，供 facade/noexcept 等单元复用

// 常见类型断言失败消息（保持与现有测试/示例一致的英文措辞与大小写）
const
  JSON_ERR_VALUE_NOT_BOOLEAN = 'Value is not a boolean';
  JSON_ERR_VALUE_NOT_NUMBER  = 'Value is not a number';
  JSON_ERR_VALUE_NOT_STRING  = 'Value is not a string';
  JSON_ERR_VALUE_NOT_ARRAY   = 'Value is not an array';
  JSON_ERR_VALUE_NOT_OBJECT  = 'Value is not an object';
  JSON_ERR_DOCUMENT_IS_NIL   = 'Document is nil';
  JSON_ERR_INVALID_DOCUMENT  = 'Invalid document impl';
  JSON_ERR_NO_ROOT_VALUE     = 'Document has no root value';
  JSON_ERR_INVALID_NUMBER_TYPE = 'Invalid number type';
  JSON_ERR_NUMBER_OUT_OF_RANGE = 'Number out of range';

// 针对解析错误码给出默认消息；若未来需要本地化/统一风格，可在此集中调整
function JsonDefaultMessageFor(ACode: TJsonErrorCode): string;

// 根据错误记录生成标准化消息：优先使用 Err.Message，否则回退到默认，并可附带位置
function JsonFormatErrorMessage(const Err: TJsonError; IncludePosition: Boolean = True): string;

implementation

function JsonDefaultMessageFor(ACode: TJsonErrorCode): string;
begin
  // Default to unknown to avoid unreachable-else warning
  Result := 'unknown error';
  case ACode of
    jecSuccess:               Result := 'success';
    jecInvalidParameter:      Result := 'invalid parameter';
    jecMemoryAllocation:      Result := 'out of memory';
    jecEmptyContent:          Result := 'input data is empty';
    jecUnexpectedContent:     Result := 'unexpected content';
    jecUnexpectedEnd:         Result := 'unexpected end of input';
    jecUnexpectedCharacter:   Result := 'unexpected character';
    jecJsonStructure:         Result := 'invalid json structure';
    jecInvalidComment:        Result := 'invalid comment';
    jecInvalidNumber:         Result := 'invalid number';
    jecInvalidString:         Result := 'invalid string';
    jecInvalidLiteral:        Result := 'invalid literal';
    jecFileOpenError:         Result := 'failed to open file';
    jecFileReadError:         Result := 'failed to read file';
    jecMore:                  Result := 'more';
  end;
end;

function JsonFormatErrorMessage(const Err: TJsonError; IncludePosition: Boolean): string;
var
  BaseMsg: string;
begin
  if Err.Message <> '' then
    BaseMsg := Err.Message
  else
    BaseMsg := JsonDefaultMessageFor(Err.Code);

  if IncludePosition then
    Result := Format('%s at position %d', [BaseMsg, Err.Position])
  else
    Result := BaseMsg;
end;

end.

