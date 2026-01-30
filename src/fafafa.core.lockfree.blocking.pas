unit fafafa.core.lockfree.blocking;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.lockfree.backoff;

type
  // 简单阻塞策略接口：将阻塞/让出动作外置，方便测试与替换
  IBlockingPolicy = interface
    ['{E7A4BE45-7A3E-4D61-8D3F-2C2B7A0B1D7F}']
    procedure Step(var SpinCount: Integer);
  end;

// 默认策略：使用 BackoffStep 进行让出（Sleep(0) 为主，偶发 Sleep(1)）
function GetDefaultBlockingPolicy: IBlockingPolicy;
// 纯自旋（不让出），用于调试/极端性能对比
function GetNoopBlockingPolicy: IBlockingPolicy;

implementation

var
  GDefaultBlocking: IBlockingPolicy = nil;
  GNoopBlocking: IBlockingPolicy = nil;

type
  TDefaultBlockingPolicy = class(TInterfacedObject, IBlockingPolicy)
  public
    procedure Step(var SpinCount: Integer);
  end;

  TNoopBlockingPolicy = class(TInterfacedObject, IBlockingPolicy)
  public
    procedure Step(var SpinCount: Integer);
  end;

procedure TDefaultBlockingPolicy.Step(var SpinCount: Integer);
begin
  BackoffStep(SpinCount);
end;

procedure TNoopBlockingPolicy.Step(var SpinCount: Integer);
begin
  Inc(SpinCount); // 计数但不让出
end;

function GetDefaultBlockingPolicy: IBlockingPolicy;
begin
  if GDefaultBlocking = nil then
    GDefaultBlocking := TDefaultBlockingPolicy.Create;
  Result := GDefaultBlocking;
end;

function GetNoopBlockingPolicy: IBlockingPolicy;
begin
  if GNoopBlocking = nil then
    GNoopBlocking := TNoopBlockingPolicy.Create;
  Result := GNoopBlocking;
end;

end.

