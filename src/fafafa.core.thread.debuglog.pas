unit fafafa.core.thread.debuglog;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

// 允许以 FAFAFA_THREAD_DEBUG 开启日志，兼容已有的 FAFAFA_CORE_THREAD_LOG 开关
{$IFDEF FAFAFA_THREAD_DEBUG}
  {$DEFINE FAFAFA_CORE_THREAD_LOG}
{$ENDIF}

interface

procedure DebugLog(const S: string);

implementation

{$IFDEF FAFAFA_CORE_THREAD_LOG}
uses
  SysUtils;

var
  GEnabled: Boolean = False;
  GInitialized: Boolean = False;
  GLogAssigned: Boolean = False;
  GLogFile: Text;

function EnvLogEnabled: Boolean;
var
  V: String;
begin
  V := GetEnvironmentVariable('FAFAFA_THREAD_LOG');
  if V = '' then Exit(False);
  if (V = '0') or (LowerCase(V) = 'false') or (LowerCase(V) = 'off') then Exit(False);
  Exit(True);
end;

procedure InitIfNeeded;
var
  ExeDir, LogsDir, FileName: string;
begin
  if GInitialized then Exit;
  GInitialized := True;
  try
    GEnabled := EnvLogEnabled;
    if not GEnabled then Exit;

    ExeDir := ExtractFilePath(ParamStr(0));
    LogsDir := IncludeTrailingPathDelimiter(ExeDir) + 'logs';
    ForceDirectories(LogsDir);
    FileName := Format('%s%sthread_%s_%5.5d.log',
      [LogsDir, DirectorySeparator,
       FormatDateTime('yyyymmdd_hhnnss', Now), Random(100000)]);
    AssignFile(GLogFile, FileName);
    Rewrite(GLogFile);
    GLogAssigned := True;

    // 首行标记
    WriteLn(GLogFile, '--- fafafa.core.thread debug log start ---');
    Flush(GLogFile);
  except
    on E: Exception do
    begin
      // 如果日志初始化失败，则禁用日志，避免影响主流程
      GEnabled := False;
      if GLogAssigned then CloseFile(GLogFile);
      GLogAssigned := False;
    end;
  end;
end;

procedure DebugLog(const S: string);
var
  TS: QWord;
begin
  if not GInitialized then InitIfNeeded;
  if not GEnabled then Exit;
  if not GLogAssigned then Exit;
  TS := GetTickCount64;
  try
    WriteLn(GLogFile, IntToStr(TS) + ' | ' + S);
    Flush(GLogFile);
  except
    // 忽略日志写入错误
  end;
end;

finalization
  try
    if GLogAssigned then
      CloseFile(GLogFile);
  except
  end;
{$ELSE}
// 日志默认编译为空；仅当定义 FAFAFA_CORE_THREAD_LOG 时启用
procedure DebugLog(const S: string); inline;
begin
  // no-op
end;
{$ENDIF}

end.
