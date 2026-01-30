unit fafafa.core.logging.sinks.rollingfile.daily;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.io;

type
  TNowProvider = function: TDateTime;

  { 按日期滚动的文本文件 Sink：basePath.YYYYMMDD，保留 MaxFiles 个历史 }
  TRollingDailyTextFileSink = class(TInterfacedObject, ITextSink)
  private
    FBasePath: string;
    FMaxFiles: Integer;
    FMaxDays: Integer; // 0 表示不按天数清理
    FNow: TNowProvider;
    FCurKey: string;
    FCurFilePath: string;
    FFile: Text;
    FOpened: Boolean;
    FLock: ILock;
  private
    function TodayKey: string;
    procedure EnsureOpen;
    procedure OpenForKey(const AKey: string);
    procedure CleanupOldFiles;
  public
    constructor Create(const ABasePath: string; AMaxFiles: Integer = 7; ANow: TNowProvider = nil; AMaxDays: Integer = 0);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

uses DateUtils;

function DefaultNow: TDateTime;
begin
  Result := Now;
end;

constructor TRollingDailyTextFileSink.Create(const ABasePath: string; AMaxFiles: Integer; ANow: TNowProvider; AMaxDays: Integer);
begin
  inherited Create;
  if ABasePath = '' then raise EArgumentException.Create('base path');
  if AMaxFiles < 1 then AMaxFiles := 1;
  FBasePath := ABasePath;
  FMaxFiles := AMaxFiles;
  FMaxDays := AMaxDays;
  if Assigned(ANow) then FNow := ANow else FNow := @DefaultNow;
  FCurKey := '';
  FCurFilePath := '';
  FOpened := False;
  FLock := TMutex.Create;
end;

destructor TRollingDailyTextFileSink.Destroy;
begin
  if FOpened then CloseFile(FFile);
  inherited Destroy;
end;

function TRollingDailyTextFileSink.TodayKey: string;
begin
  Result := FormatDateTime('yyyymmdd', FNow());
end;

procedure TRollingDailyTextFileSink.OpenForKey(const AKey: string);
var Path: string;
begin
  Path := FBasePath + '.' + AKey;
  AssignFile(FFile, Path);
  if FileExists(Path) then Append(FFile) else Rewrite(FFile);
  FOpened := True;
  FCurKey := AKey;
  FCurFilePath := Path;
end;

procedure TRollingDailyTextFileSink.CleanupOldFiles;
var
  Dir, BaseName, Mask: string;
  SR: TSearchRec;
  Files: TStringList;
  FN: string;
  I, CutDate, FileDate: Integer;
  Today: TDateTime;
begin
  Dir := ExtractFilePath(FBasePath);
  BaseName := ExtractFileName(FBasePath);
  if Dir = '' then Dir := '.' + DirectorySeparator;
  Mask := BaseName + '.*';
  Files := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + Mask, faAnyFile and not faDirectory, SR) = 0 then
    begin
      repeat
        FN := SR.Name;
        // 筛选出 BaseName.YYYYMMDD
        if Pos(BaseName + '.', FN) = 1 then
        begin
          // 后缀 8 位数字
          if (Length(FN) = Length(BaseName) + 1 + 8) then
          begin
            if TryStrToInt(Copy(FN, Length(BaseName)+2, 8), I) then
              Files.Add(FN);
          end;
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;
    // 按文件名排序（yyyymmdd 字典序即时间序）
    Files.Sort;
    while Files.Count > FMaxFiles do
    begin
      FN := Files[0];
      DeleteFile(IncludeTrailingPathDelimiter(Dir) + FN);
      Files.Delete(0);
    end;
    // MaxDays 清理（如果开启）
    if FMaxDays > 0 then
    begin
      Today := FNow();
      // 阈值：保留 [Today - (MaxDays-1), Today]，删除 < (Today - (MaxDays-1))
      CutDate := StrToIntDef(FormatDateTime('yyyymmdd', Today - FMaxDays + 1), 0);
      I := 0;
      while I < Files.Count do
      begin
        FN := Files[I];
        // 解析成 yyyymmdd 数字
        FileDate := StrToIntDef(Copy(FN, Length(BaseName)+2, 8), 0);
        if (FileDate > 0) and (FileDate < CutDate) then
        begin
          DeleteFile(IncludeTrailingPathDelimiter(Dir) + FN);
          Files.Delete(I);
          Continue;
        end;
        Inc(I);
      end;
    end;
  finally
    Files.Free;
  end;
end;

procedure TRollingDailyTextFileSink.EnsureOpen;
var Key: string;
begin
  Key := TodayKey;
  if not FOpened then
  begin
    OpenForKey(Key);
    CleanupOldFiles;
    Exit;
  end;
  if Key <> FCurKey then
  begin
    CloseFile(FFile);
    FOpened := False;
    OpenForKey(Key);
    CleanupOldFiles;
  end;
end;

procedure TRollingDailyTextFileSink.WriteLine(const S: string);
var LAuto: TAutoLock;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    EnsureOpen;
    System.WriteLn(FFile, S);
  finally
    LAuto.Free;
  end;
end;

procedure TRollingDailyTextFileSink.Flush;
var LAuto: TAutoLock;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    if FOpened then System.Flush(FFile);
  finally
    LAuto.Free;
  end;
end;

end.

