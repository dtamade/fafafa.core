unit fafafa.core.time.testhooks;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time;

{$IFDEF MSWINDOWS}
procedure Test_ForceUseGTC64_ForWindows(AForce: Boolean);
function Test_GetWindowsQpcFallbackCount: LongWord;
{$ENDIF}
{$IFDEF DARWIN}
function Test_DarwinTimebaseIsFallback: Boolean;
{$ENDIF}


implementation

{$IFDEF MSWINDOWS}
procedure Test_ForceUseGTC64_ForWindows(AForce: Boolean);
begin
  // 委托给 fafafa.core.time 中的测试钩子（避免直接访问私有字段）
  fafafa.core.time.Test_ForceUseGTC64_ForWindows(AForce);
end;

function Test_GetWindowsQpcFallbackCount: LongWord;
begin
  Result := fafafa.core.time.Test_GetWindowsQpcFallbackCount();
end;
{$ENDIF}

{$IFDEF DARWIN}
function Test_DarwinTimebaseIsFallback: Boolean;
begin
  Result := fafafa.core.time.Test_DarwinTimebaseIsFallback();
end;
{$ENDIF}

end.

