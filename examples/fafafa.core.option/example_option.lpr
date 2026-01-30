program example_option;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.option.base;

type
  TIntOption = specialize TOption<Integer>;
  TStrOption = specialize TOption<string>;

procedure DemoBasicUsage;
var
  Opt: TIntOption;
begin
  WriteLn('=== 基本用法 ===');
  
  // 创建 Some 值
  Opt := TIntOption.Some(42);
  WriteLn('IsSome: ', Opt.IsSome);  // True
  WriteLn('IsNone: ', Opt.IsNone);  // False
  WriteLn('Unwrap: ', Opt.Unwrap);  // 42
  
  // 创建 None 值
  Opt := TIntOption.None;
  WriteLn('IsSome: ', Opt.IsSome);  // False
  WriteLn('IsNone: ', Opt.IsNone);  // True
  WriteLn;
end;

procedure DemoUnwrapOr;
var
  Opt: TIntOption;
begin
  WriteLn('=== UnwrapOr 默认值 ===');
  
  Opt := TIntOption.Some(100);
  WriteLn('Some(100).UnwrapOr(0) = ', Opt.UnwrapOr(0));  // 100
  
  Opt := TIntOption.None;
  WriteLn('None.UnwrapOr(0) = ', Opt.UnwrapOr(0));  // 0
  WriteLn;
end;

procedure DemoStringOption;
var
  Opt: TStrOption;
begin
  WriteLn('=== 字符串 Option ===');
  
  Opt := TStrOption.Some('Hello, World!');
  if Opt.IsSome then
    WriteLn('值: ', Opt.Unwrap);
  
  Opt := TStrOption.None;
  WriteLn('默认值: ', Opt.UnwrapOr('(空)'));
  WriteLn;
end;

function FindUser(ID: Integer): TStrOption;
begin
  // 模拟查找用户
  if ID = 1 then
    Result := TStrOption.Some('Alice')
  else if ID = 2 then
    Result := TStrOption.Some('Bob')
  else
    Result := TStrOption.None;
end;

procedure DemoRealWorldUsage;
var
  User: TStrOption;
begin
  WriteLn('=== 实际应用场景 ===');
  
  User := FindUser(1);
  WriteLn('查找用户 1: ', User.UnwrapOr('未找到'));
  
  User := FindUser(2);
  WriteLn('查找用户 2: ', User.UnwrapOr('未找到'));
  
  User := FindUser(999);
  WriteLn('查找用户 999: ', User.UnwrapOr('未找到'));
  WriteLn;
end;

procedure DemoSafeAccess;
var
  Opt: TIntOption;
begin
  WriteLn('=== 安全访问模式 ===');
  
  Opt := TIntOption.None;
  
  // 安全方式：先检查再访问
  if Opt.IsSome then
    WriteLn('值: ', Opt.Unwrap)
  else
    WriteLn('值不存在，使用默认值');
  
  // 更简洁的方式
  WriteLn('使用 UnwrapOr: ', Opt.UnwrapOr(-1));
  WriteLn;
end;

begin
  WriteLn('fafafa.core.option 示例程序');
  WriteLn('===========================');
  WriteLn;
  
  DemoBasicUsage;
  DemoUnwrapOr;
  DemoStringOption;
  DemoRealWorldUsage;
  DemoSafeAccess;
  
  WriteLn('示例程序完成!');
end.
