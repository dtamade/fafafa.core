unit fafafa.core.sync.once;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.once.base
  {$IFDEF WINDOWS}, fafafa.core.sync.once.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.once.unix{$ENDIF};

type

  IOnce = fafafa.core.sync.once.base.IOnce;

  {$IFDEF WINDOWS}
  TOnce = fafafa.core.sync.once.windows.TOnce;
  {$ENDIF}

  {$IFDEF UNIX}
  TOnce = fafafa.core.sync.once.unix.TOnce;
  {$ENDIF}

// 创建平台特定的一次性执行实例（Go/Rust 风格：无状态构造）
function MakeOnce: IOnce; overload;

// 构造时传入回调的工厂函数（现代语言风格）
function MakeOnce(const AProc: TOnceProc): IOnce; overload;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload;
{$ENDIF}



implementation

function MakeOnce: IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create;
  {$ENDIF}
end;

function MakeOnce(const AProc: TOnceProc): IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AProc);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AProc);
  {$ENDIF}
end;

function MakeOnce(const AMethod: TOnceMethod): IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AMethod);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AMethod);
  {$ENDIF}
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AAnonymousProc);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AAnonymousProc);
  {$ENDIF}
end;
{$ENDIF}



end.
