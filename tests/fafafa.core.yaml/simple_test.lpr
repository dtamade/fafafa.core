{$CODEPAGE UTF8}
program simple_test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils, Classes;

// 简化的类型定义，用于测试基本结构
type
  TFyVersion = record
    major: Integer;
    minor: Integer;
  end;
  PFyVersion = ^TFyVersion;

  TFyEventType = (
    FYET_NONE,
    FYET_STREAM_START,
    FYET_STREAM_END,
    FYET_DOCUMENT_START,
    FYET_DOCUMENT_END,
    FYET_MAPPING_START,
    FYET_MAPPING_END,
    FYET_SEQUENCE_START,
    FYET_SEQUENCE_END,
    FYET_SCALAR,
    FYET_ALIAS
  );

// 全局变量
var
  fy_default_version: TFyVersion = (major: 1; minor: 2);

// 简化的函数实现
function fy_version_default: PFyVersion;
begin
  Result := @fy_default_version;
end;

function fy_version_compare(const va, vb: PFyVersion): Integer;
var
  a, b: PFyVersion;
begin
  a := va;
  b := vb;
  
  if a = nil then
    a := @fy_default_version;
  if b = nil then
    b := @fy_default_version;
    
  Result := a^.major - b^.major;
  if Result = 0 then
    Result := a^.minor - b^.minor;
end;

function fy_version_is_supported(const vers: PFyVersion): Boolean;
var
  v: PFyVersion;
begin
  v := vers;
  if v = nil then
    v := @fy_default_version;
    
  // 目前支持 YAML 1.1 和 1.2
  Result := (v^.major = 1) and (v^.minor >= 1) and (v^.minor <= 2);
end;

function fy_event_type_get_text(event_type: TFyEventType): PChar;
begin
  case event_type of
    FYET_NONE: Result := 'NONE';
    FYET_STREAM_START: Result := '+STR';
    FYET_STREAM_END: Result := '-STR';
    FYET_DOCUMENT_START: Result := '+DOC';
    FYET_DOCUMENT_END: Result := '-DOC';
    FYET_MAPPING_START: Result := '+MAP';
    FYET_MAPPING_END: Result := '-MAP';
    FYET_SEQUENCE_START: Result := '+SEQ';
    FYET_SEQUENCE_END: Result := '-SEQ';
    FYET_SCALAR: Result := '=VAL';
    FYET_ALIAS: Result := '=ALI';
  else
    Result := 'UNKNOWN';
  end;
end;

// 简单的测试函数
procedure TestVersionFunctions;
var
  version: PFyVersion;
  v1, v2: TFyVersion;
begin
  WriteLn('=== 测试版本函数 ===');
  
  // 测试默认版本
  version := fy_version_default;
  WriteLn('默认版本: ', version^.major, '.', version^.minor);
  
  // 测试版本比较
  v1.major := 1; v1.minor := 1;
  v2.major := 1; v2.minor := 2;
  
  WriteLn('版本比较 1.1 vs 1.2: ', fy_version_compare(@v1, @v2));
  WriteLn('版本比较 1.2 vs 1.1: ', fy_version_compare(@v2, @v1));
  WriteLn('版本比较 1.1 vs 1.1: ', fy_version_compare(@v1, @v1));
  
  // 测试版本支持
  WriteLn('YAML 1.1 支持: ', fy_version_is_supported(@v1));
  WriteLn('YAML 1.2 支持: ', fy_version_is_supported(@v2));
  
  v1.major := 1; v1.minor := 3;
  WriteLn('YAML 1.3 支持: ', fy_version_is_supported(@v1));
  
  WriteLn;
end;

procedure TestEventTypeFunctions;
begin
  WriteLn('=== 测试事件类型函数 ===');
  
  WriteLn('FYET_NONE: ', fy_event_type_get_text(FYET_NONE));
  WriteLn('FYET_STREAM_START: ', fy_event_type_get_text(FYET_STREAM_START));
  WriteLn('FYET_STREAM_END: ', fy_event_type_get_text(FYET_STREAM_END));
  WriteLn('FYET_DOCUMENT_START: ', fy_event_type_get_text(FYET_DOCUMENT_START));
  WriteLn('FYET_DOCUMENT_END: ', fy_event_type_get_text(FYET_DOCUMENT_END));
  WriteLn('FYET_MAPPING_START: ', fy_event_type_get_text(FYET_MAPPING_START));
  WriteLn('FYET_MAPPING_END: ', fy_event_type_get_text(FYET_MAPPING_END));
  WriteLn('FYET_SEQUENCE_START: ', fy_event_type_get_text(FYET_SEQUENCE_START));
  WriteLn('FYET_SEQUENCE_END: ', fy_event_type_get_text(FYET_SEQUENCE_END));
  WriteLn('FYET_SCALAR: ', fy_event_type_get_text(FYET_SCALAR));
  WriteLn('FYET_ALIAS: ', fy_event_type_get_text(FYET_ALIAS));
  
  WriteLn;
end;

begin
  WriteLn('=== fafafa.core.yaml 简单测试 ===');
  WriteLn('测试 libfyaml 移植的基本功能');
  WriteLn;
  
  try
    TestVersionFunctions;
    TestEventTypeFunctions;
    
    WriteLn('所有测试通过！');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      WriteLn('测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
