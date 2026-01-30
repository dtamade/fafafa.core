{$CODEPAGE UTF8}
unit fafafa.core.term.helpers;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fafafa.core.term;

// 检测是否运行在 Windows Terminal（简易版）：
// - Windows Terminal 会设置环境变量 WT_SESSION/WT_PROFILE_ID
function term_is_windows_terminal: Boolean;

// 0 = auto, 1 = ascii, 2 = box
function term_choose_border_mode(const anyMouseSupported: Integer; const isWindowsTerminal: Boolean): Integer;
// 根据模式与能力，得到是否使用 ASCII 边框（True=ASCII，False=Box）
function term_use_ascii_border(const borderMode: Integer; const anyMouseSupported: Integer; const isWindowsTerminal: Boolean): Boolean;

implementation

function term_is_windows_terminal: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (SysUtils.GetEnvironmentVariable('WT_SESSION') <> '') or
            (SysUtils.GetEnvironmentVariable('WT_PROFILE_ID') <> '');
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function term_choose_border_mode(const anyMouseSupported: Integer; const isWindowsTerminal: Boolean): Integer;
begin
  // 自动策略：Windows Terminal 或不支持任意鼠标移动 -> ASCII；否则 box
  if (anyMouseSupported = -1) or isWindowsTerminal then
    Result := 1
  else
    Result := 2;
end;

function term_use_ascii_border(const borderMode: Integer; const anyMouseSupported: Integer; const isWindowsTerminal: Boolean): Boolean;
begin
  case borderMode of
    1: Result := True;   // ascii
    2: Result := False;  // box
  else
    // auto
    Result := (anyMouseSupported = -1) or isWindowsTerminal;
  end;
end;

end.

