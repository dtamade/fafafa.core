unit fafafa.core.sync.namedSharedCounter.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  // ===== SharedCounter 配置 =====
  TNamedSharedCounterConfig = record
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialValue: Int64;           // 初始值
  end;

  // ===== 跨进程原子计数器接口 =====
  INamedSharedCounter = interface(ISynchronizable)
    ['{A4B5C6D7-E8F9-0A1B-2C3D-4E5F6A7B8C9D}']
    // 增加/减少
    function Increment: Int64;
    function Decrement: Int64;
    function Add(AValue: Int64): Int64;
    function Sub(AValue: Int64): Int64;

    // 原子操作
    function CompareExchange(AExpected, ANew: Int64): Int64;
    function Exchange(ANew: Int64): Int64;

    // 读取/设置
    function GetValue: Int64;
    procedure SetValue(AValue: Int64);

    // 元信息
    function GetName: string;

    property Value: Int64 read GetValue write SetValue;
  end;

// 配置辅助函数
function DefaultNamedSharedCounterConfig: TNamedSharedCounterConfig; inline;
function NamedSharedCounterConfigWithInitial(AInitialValue: Int64): TNamedSharedCounterConfig; inline;
function GlobalNamedSharedCounterConfig: TNamedSharedCounterConfig; inline;

implementation

function DefaultNamedSharedCounterConfig: TNamedSharedCounterConfig;
begin
  Result.UseGlobalNamespace := False;
  Result.InitialValue := 0;
end;

function NamedSharedCounterConfigWithInitial(AInitialValue: Int64): TNamedSharedCounterConfig;
begin
  Result := DefaultNamedSharedCounterConfig;
  Result.InitialValue := AInitialValue;
end;

function GlobalNamedSharedCounterConfig: TNamedSharedCounterConfig;
begin
  Result := DefaultNamedSharedCounterConfig;
  Result.UseGlobalNamespace := True;
end;

end.
