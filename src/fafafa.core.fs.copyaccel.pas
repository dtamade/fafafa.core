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
  SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF}
  , fafafa.core.fs.errors;

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
  // 平台实现：Windows 采用 CopyFileExW；其他平台暂未启用加速（返回未知，调用方回退）
  {$IFDEF WINDOWS}
  if not FsCopyAccelIsEnabled then
  begin
    Result := -999; // 未启用：交由调用方回退
    Exit;
  end;
  aUsedAccel := True;
  // 若允许覆盖且目标存在，先删除（CopyFileEx/CopyFile 均在目标存在时失败）
  if aOverwrite then
    Windows.DeleteFileW(PWideChar(UTF8Decode(aDst)));
  if CopyFileExW(PWideChar(UTF8Decode(aSrc)), PWideChar(UTF8Decode(aDst)), nil, nil, nil, 0) then
    Exit(0);
  // 失败：统一错误码
  Result := Integer(SystemErrorToFsError(GetLastError()));
  {$ELSE}
  // 其他平台暂未实现加速，提示调用方回退
  Result := -999; // FS_ERROR_UNKNOWN
  {$ENDIF}
end;

function FsCopyAccelTryMoveFile(const aSrc, aDst: string; aOverwrite: Boolean; out aUsedAccel: Boolean): Integer;
begin
  aUsedAccel := False;
  {$IFDEF WINDOWS}
  if not FsCopyAccelIsEnabled then
  begin
    Result := -999;
    Exit;
  end;
  aUsedAccel := True;
  if MoveFileExW(
       PWideChar(UTF8Decode(aSrc)),
       PWideChar(UTF8Decode(aDst)),
       (MOVEFILE_COPY_ALLOWED) or (if aOverwrite then MOVEFILE_REPLACE_EXISTING else 0)
     ) then
    Exit(0);
  Result := Integer(SystemErrorToFsError(GetLastError()));
  {$ELSE}
  Result := -999; // 其他平台暂未实现加速
  {$ENDIF}
end;

end.

