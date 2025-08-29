unit fafafa.core.sync.spinMutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.spinMutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.spinMutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.spinMutex.unix{$ENDIF};

type
  // 公开接口类型 - 完全隐藏平台差异
  ISpinMutex = fafafa.core.sync.spinMutex.base.ISpinMutex;

  // 注意：TSpinMutex 具体类型不再公开导出
  // 用户应该只使用 ISpinMutex 接口和工厂函数

// ===== 简化工厂函数接口 =====
function MakeSpinMutex: ISpinMutex; overload;
function MakeSpinMutex(ASpinCount: Integer): ISpinMutex; overload;

implementation

// ===== 简化工厂函数实现 =====

function MakeSpinMutex(ASpinCount: Integer): ISpinMutex;
begin
  // 创建平台特定实例
  {$IFDEF UNIX}
  Result := fafafa.core.sync.spinMutex.unix.TSpinMutex.Create(ASpinCount);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.spinMutex.windows.TSpinMutex.Create(ASpinCount);
  {$ENDIF}
end;

function MakeSpinMutex: ISpinMutex;
begin
  Result := MakeSpinMutex(1000); // 默认自旋次数
end;

end.

