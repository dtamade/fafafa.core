unit fafafa.core.fs.copyaccel;

{$mode objfpc}{$H+}

{!
  内核加速复制/移动（CopyAccel）占位单元（草案）
  - 不改变对外 API；供内部调用选择更优路径（如 CopyFile2/copy_file_range）
  - 当前仅提供能力开关与占位实现，默认不启用真实加速（返回未实现）
  - 控制：
    * 编译期：定义 FAFAFA_CORE_FS_DISABLE_COPYACCEL 则始终禁用
    * 运行时：环境变量 FAFAFA_FS_COPYACCEL=0 禁用，=1 启用（默认启用）
}

interface

uses
  SysUtils;

// 运行时是否启用 CopyAccel（受编译宏与环境变量控制）
function FsCopyAccelIsEnabled: Boolean;

// 试图使用内核加速路径复制单个文件；
// 返回：0 成功；<0 FsErrorCode 负码；若未采用加速路径，aUsedAccel=False 且可由调用方回退
function FsCopyAccelTryCopyFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;

// 试图使用内核加速路径移动单个文件；其余语义与 FsCopyAccelTryCopyFile 相同
function FsCopyAccelTryMoveFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;

implementation

function EnvEnabled: Boolean;
var
  V: String;
begin
  V := GetEnvironmentVariable('FAFAFA_FS_COPYACCEL');
  if V = '' then Exit(True);
  Result := not ((V = '0') or (LowerCase(V) = 'false'));
end;

function FsCopyAccelIsEnabled: Boolean;
begin
  {$IFDEF FAFAFA_CORE_FS_DISABLE_COPYACCEL}
  Exit(False);
  {$ENDIF}
  Result := EnvEnabled;
end;

function FsCopyAccelTryCopyFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;
begin
  aUsedAccel := False;
  // 占位：当前未实现真实加速路径；调用方应在返回非 0 或未使用加速时回退到安全路径
  Result := -999; // FS_ERROR_UNKNOWN
end;

function FsCopyAccelTryMoveFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;
begin
  aUsedAccel := False;
  // 占位：当前未实现真实加速路径；调用方应回退
  Result := -999; // FS_ERROR_UNKNOWN
end;

end.

