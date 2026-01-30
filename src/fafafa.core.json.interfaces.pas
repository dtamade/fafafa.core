unit fafafa.core.json.interfaces;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

// 注意：本单元仅作为“别名/转发层”，不再重复定义接口与 GUID。
// 统一以 fafafa.core.json（facade）作为接口来源，避免漂移。

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json; // 引入门面，供接口别名使用

type
  // 继续对外暴露 fixed 层类型（Flags/错误码/基础类型）
  TJsonReadFlags = fafafa.core.json.core.TJsonReadFlags;
  TJsonWriteFlags = fafafa.core.json.core.TJsonWriteFlags;
  TJsonErrorCode = fafafa.core.json.core.TJsonErrorCode;
  TJsonDocument = fafafa.core.json.core.TJsonDocument;
  PJsonValue = fafafa.core.json.core.PJsonValue;

  // 接口别名：直接指向门面中的接口定义
  IJsonValue = fafafa.core.json.IJsonValue;
  IJsonDocument = fafafa.core.json.IJsonDocument;
  IJsonReader = fafafa.core.json.IJsonReader;
  IJsonWriter = fafafa.core.json.IJsonWriter;

  // 异常别名（如有历史代码引用）
  EJsonParseError = fafafa.core.json.EJsonParseError;


  // 额外导出 UTF-8 友好的字符串 API
  function JsonGetStrUtf8(AVal: PJsonValue): UTF8String; inline; export name 'JsonGetStrUtf8';
  function JsonEqualsStrUtf8(AVal: PJsonValue; const S: UTF8String): Boolean; inline; export name 'JsonEqualsStrUtf8';

// 工厂与便捷函数请直接 uses fafafa.core.json 调用

implementation

function JsonGetStrUtf8(AVal: PJsonValue): UTF8String; inline;
begin
  Result := fafafa.core.json.core.JsonGetStrUtf8(AVal);
end;

function JsonEqualsStrUtf8(AVal: PJsonValue; const S: UTF8String): Boolean; inline;
begin
  Result := fafafa.core.json.core.JsonEqualsStrUtf8(AVal, S);
end;


end.
