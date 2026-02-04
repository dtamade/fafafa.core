unit fafafa.core.json.aliases;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  // 通过 interface uses 传播底层类型（Flags、错误码等）
  fafafa.core.json.types,
  // 门面接口（统一改为直接使用 fafafa.core.json 作为门面）
  fafafa.core.json;  // actual facade unit

type
  // 直接别名到门面接口，避免重复定义与 GUID 冲突
  IJsonValue = fafafa.core.json.IJsonValue;
  IJsonDocument = fafafa.core.json.IJsonDocument;
  IJsonReader = fafafa.core.json.IJsonReader;
  IJsonWriter = fafafa.core.json.IJsonWriter;

  EJsonParseError = fafafa.core.json.EJsonParseError;

// 将 fixed 文档包装与 JSON Pointer 便捷调用也在别名层转发，便于历史代码迁移
function JsonWrapDocument(ADoc: fafafa.core.json.core.TJsonDocument): IJsonDocument;
function JsonPointerGet(ARoot: IJsonValue; const APointer: String): IJsonValue; overload;
function JsonPointerGet(ADoc: IJsonDocument; const APointer: String): IJsonValue; overload;

// 工厂函数：委派到门面
function CreateJsonReader(AAllocator: IAllocator = nil): IJsonReader;
function CreateJsonWriter: IJsonWriter;

implementation

function CreateJsonReader(AAllocator: IAllocator): IJsonReader;
begin
  Result := fafafa.core.json.CreateJsonReader(AAllocator);
end;

function CreateJsonWriter: IJsonWriter;
begin
  Result := fafafa.core.json.CreateJsonWriter;
end;

function JsonWrapDocument(ADoc: fafafa.core.json.core.TJsonDocument): IJsonDocument;
begin
  Result := fafafa.core.json.JsonWrapDocument(ADoc);
end;

function JsonPointerGet(ARoot: IJsonValue; const APointer: String): IJsonValue;
begin
  Result := fafafa.core.json.JsonPointerGet(ARoot, APointer);
end;

function JsonPointerGet(ADoc: IJsonDocument; const APointer: String): IJsonValue;
begin
  Result := fafafa.core.json.JsonPointerGet(ADoc, APointer);
end;

end.

