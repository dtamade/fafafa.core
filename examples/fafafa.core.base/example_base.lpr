program example_base;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base;

type
  TIntStrPair = specialize TTuple2<Integer, string>;
  TStrStrPair = specialize TTuple2<string, string>;

procedure DemoVersion;
begin
  WriteLn('=== 版本信息 ===');
  WriteLn('fafafa.core.base 版本: ', FAFAFA_CORE_BASE_VERSION);
  WriteLn;
end;

procedure DemoConstants;
begin
  WriteLn('=== 数值常量 ===');
  WriteLn('MAX_INT32: ', MAX_INT32);
  WriteLn('MIN_INT32: ', MIN_INT32);
  WriteLn('MAX_INT64: ', MAX_INT64);
  WriteLn('MIN_INT64: ', MIN_INT64);
  WriteLn('SIZE_PTR: ', SIZE_PTR, ' bytes');
  WriteLn;
end;

procedure DemoTuple2;
var
  LPair1: TIntStrPair;
  LPair2: TStrStrPair;
begin
  WriteLn('=== TTuple2 泛型元组 ===');
  
  // 创建 Integer-String 元组
  LPair1 := TIntStrPair.Create(42, 'hello');
  WriteLn('Pair1.First: ', LPair1.First);
  WriteLn('Pair1.Second: ', LPair1.Second);
  
  // 创建 String-String 元组
  LPair2 := TStrStrPair.Create('key', 'value');
  WriteLn('Pair2.First: ', LPair2.First);
  WriteLn('Pair2.Second: ', LPair2.Second);
  WriteLn;
end;

procedure DemoExceptions;
begin
  WriteLn('=== 异常体系 ===');
  
  // 演示 EOutOfRange
  try
    raise EOutOfRange.Create('索引 10 超出范围 [0..5]');
  except
    on E: ECore do
      WriteLn('捕获 ECore 异常: ', E.Message);
  end;
  
  // 演示 EArgumentNil
  try
    raise EArgumentNil.Create('参数 Data 不能为 nil');
  except
    on E: EArgumentNil do
      WriteLn('捕获 EArgumentNil: ', E.Message);
  end;
  
  // 演示 EInvalidArgument
  try
    raise EInvalidArgument.Create('无效的参数值');
  except
    on E: EInvalidArgument do
      WriteLn('捕获 EInvalidArgument: ', E.Message);
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.base 示例程序');
  WriteLn('========================');
  WriteLn;
  
  DemoVersion;
  DemoConstants;
  DemoTuple2;
  DemoExceptions;
  
  WriteLn('示例程序完成!');
end.
