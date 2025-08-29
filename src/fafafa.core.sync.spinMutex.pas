unit fafafa.core.sync.spinMutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.spinMutex.base, fafafa.core.sync.spinMutex.impl;

type
  // 公开接口类型 - 完全隐藏平台差异
  ISpinMutex = fafafa.core.sync.spinMutex.base.ISpinMutex;

  // 注意：TSpinMutex 具体类型不再公开导出
  // 用户应该只使用 ISpinMutex 接口和工厂函数

// ===== 工厂函数接口 =====
function MakeSpinMutex: ISpinMutex; overload;
function MakeSpinMutex(ASpinCount: Integer): ISpinMutex; overload;
function MakeSpinMutex(const AName: string): ISpinMutex; overload;
function MakeSpinMutex(const AName: string; const AConfig: TSpinMutexConfig): ISpinMutex; overload;

// 便捷构造函数
function MakeHighPerformanceSpinMutex(const AName: string): ISpinMutex;
function MakeLowLatencySpinMutex(const AName: string): ISpinMutex;
function MakeGlobalSpinMutex(const AName: string): ISpinMutex;

implementation

// ===== 工厂函数实现 =====

function MakeSpinMutex(const AName: string; const AConfig: TSpinMutexConfig): ISpinMutex;
begin
  // 使用新的统一实现
  Result := fafafa.core.sync.spinMutex.impl.TSpinMutex.Create(AName, AConfig);
end;

function MakeSpinMutex(const AName: string): ISpinMutex;
begin
  Result := MakeSpinMutex(AName, DefaultSpinMutexConfig);
end;

function MakeSpinMutex(ASpinCount: Integer): ISpinMutex;
var
  Config: TSpinMutexConfig;
begin
  Config := DefaultSpinMutexConfig;
  Config.MaxSpinCount := ASpinCount;
  Result := MakeSpinMutex('spinmutex', Config);
end;

function MakeSpinMutex: ISpinMutex;
begin
  Result := MakeSpinMutex(1000); // 默认自旋次数
end;

// 便捷构造函数实现
function MakeHighPerformanceSpinMutex(const AName: string): ISpinMutex;
begin
  Result := MakeSpinMutex(AName, HighPerformanceSpinMutexConfig);
end;

function MakeLowLatencySpinMutex(const AName: string): ISpinMutex;
begin
  Result := MakeSpinMutex(AName, LowLatencySpinMutexConfig);
end;

function MakeGlobalSpinMutex(const AName: string): ISpinMutex;
begin
  Result := MakeSpinMutex(AName, DefaultSpinMutexConfig);
end;

end.

