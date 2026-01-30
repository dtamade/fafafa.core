unit fafafa.core.time.timer.callback;

{$mode objfpc}
{$I fafafa.core.settings.inc}

// ✅ Phase 2.1: 从 timer.pas 拆分出的回调相关函数
// 包含：回调构造函数、执行函数

interface

uses
  fafafa.core.time.timer.base;

// 便捷构造函数
function TimerCallback(const P: TTimerProc): TTimerCallback; overload; inline;
function TimerCallback(const P: TTimerProcData; Data: Pointer): TTimerCallback; overload; inline;
function TimerCallbackMethod(const M: TTimerMethod): TTimerCallback; inline;
function TimerCallbackNested(const N: TTimerProcNested): TTimerCallback; inline;

// 回调执行
procedure ExecuteTimerCallback(const cb: TTimerCallback);

implementation

// ✅ v2.0: TTimerCallback 便捷构造函数实现
function TimerCallback(const P: TTimerProc): TTimerCallback;
begin
  Result.Kind := tckProc;
  Result.Proc := P;
end;

function TimerCallback(const P: TTimerProcData; Data: Pointer): TTimerCallback;
begin
  Result.Kind := tckProcData;
  Result.ProcData := P;
  Result.Data := Data;
end;

function TimerCallbackMethod(const M: TTimerMethod): TTimerCallback;
begin
  Result.Kind := tckMethod;
  Result.Method := M;
end;

function TimerCallbackNested(const N: TTimerProcNested): TTimerCallback;
begin
  Result.Kind := tckNested;
  Result.Nested := N;
end;

// ✅ v2.0: 回调执行
procedure ExecuteTimerCallback(const cb: TTimerCallback);
begin
  case cb.Kind of
    tckProc:
      if Assigned(cb.Proc) then cb.Proc();
    tckProcData:
      if Assigned(cb.ProcData) then cb.ProcData(cb.Data);
    tckMethod:
      if Assigned(cb.Method) then cb.Method();
    tckNested:
      if Assigned(cb.Nested) then cb.Nested();
  end;
end;

end.
