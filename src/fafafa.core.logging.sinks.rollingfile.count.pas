unit fafafa.core.logging.sinks.rollingfile.count;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.io,
  fafafa.core.logging.interfaces
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFDEF UNIX}, BaseUnix{$ENDIF};

type
  { 按行数滚动的文本文件 Sink：basePath.count-TS.NNNN，保留 MaxFiles 个历史 }
  TRollingCountTextFileSink = class(TInterfacedObject, ITextSink)
  private
    FBasePath: string;
    FMaxFiles: Integer;
    FMaxLines: QWord;
    FCurLines: QWord;
    FStream: TFileStream;
    FOpened: Boolean;
    FLock: ILock;
  private
    function MakeRollPath: string;
    procedure EnsureOpen;
    procedure Rotate;
    procedure CleanupOldFiles;
  public
    constructor Create(const ABasePath: string; AMaxLines: QWord; AMaxFiles: Integer = 7);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

function NowTimestamp: string;
var
  ts: string;
begin
  ts := FormatDateTime('yyyymmdd_hhnnss_zzz', Now);
  Result := StringReplace(ts, ':', '', [rfReplaceAll]);
end;

{ TRollingCountTextFileSink }
constructor TRollingCountTextFileSink.Create(const ABasePath: string; AMaxLines: QWord; AMaxFiles: Integer);
begin
  inherited Create;
  if ABasePath = '' then raise EArgumentException.Create('base path');
  if AMaxLines = 0 then raise EArgumentException.Create('max lines');
  if AMaxFiles < 1 then AMaxFiles := 1;
  FBasePath := ABasePath;
  FMaxFiles := AMaxFiles;
  FMaxLines := AMaxLines;
  FCurLines := 0;
  FOpened := False;
  FLock := TMutex.Create;
end;

destructor TRollingCountTextFileSink.Destroy;
begin
  if FOpened then
  begin
    FreeAndNil(FStream);
    FOpened := False;
  end;
  inherited Destroy;
end;

function TRollingCountTextFileSink.MakeRollPath: string;
var base, dir, ts: string;
begin
  dir := ExtractFilePath(FBasePath);
  base := ChangeFileExt(ExtractFileName(FBasePath), '');
  if dir = '' then dir := '.' + DirectorySeparator;
  ts := NowTimestamp;
  Result := IncludeTrailingPathDelimiter(dir) + base + '.count-' + ts;
end;

procedure TRollingCountTextFileSink.CleanupOldFiles;
var
  Dir, BaseName, Mask: string;
  SR: TSearchRec;
  Files: TStringList;
  I: Integer;
  FN, Full: string;
begin
  Dir := ExtractFilePath(FBasePath);
  BaseName := ChangeFileExt(ExtractFileName(FBasePath), '');
  if Dir = '' then Dir := '.' + DirectorySeparator;
  Mask := BaseName + '.count-*';
  Files := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + Mask, faAnyFile and not faDirectory, SR) = 0 then
    begin
      repeat
        Files.Add(SR.Name);
      until FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
    Files.Sort;
    while Files.Count > FMaxFiles do
    begin
      FN := Files[0];
      Full := IncludeTrailingPathDelimiter(Dir) + FN;
      if FileExists(Full) then SysUtils.DeleteFile(Full);
      Files.Delete(0);
    end;
  finally
    Files.Free;
  end;
end;

procedure TRollingCountTextFileSink.EnsureOpen;
begin
  if not FOpened then
  begin
    if FileExists(FBasePath) then
    begin
      FStream := TFileStream.Create(FBasePath, fmOpenReadWrite or fmShareDenyNone);
      FStream.Seek(0, soEnd);
      // 追加模式：尝试推断已有行数（粗略：按行尾统计）
      // 简化起见，不恢复历史行计数，直接从 0 开始，只要达到 FMaxLines 即轮转。
      FCurLines := 0;
    end
    else
    begin
      FStream := TFileStream.Create(FBasePath, fmCreate or fmShareDenyNone);
      FCurLines := 0;
    end;
    FOpened := True;
  end;
end;

procedure TRollingCountTextFileSink.Rotate;
begin
  if FOpened then
  begin
    FreeAndNil(FStream);
    FOpened := False;
  end;
  if FileExists(FBasePath) then
    RenameFile(FBasePath, MakeRollPath);
  CleanupOldFiles;
  EnsureOpen;
  FCurLines := 0;
end;

procedure TRollingCountTextFileSink.WriteLine(const S: string);
var
  LAuto: TAutoLock;
  U: UTF8String;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    EnsureOpen;
    // 到达阈值则先滚动
    if FCurLines >= FMaxLines then
      Rotate;
    U := UTF8String(S);
    if Length(U) > 0 then
      FStream.WriteBuffer(U[1], Length(U));
    if Length(LineEnding) > 0 then
      FStream.WriteBuffer(LineEnding[1], Length(LineEnding));
    Inc(FCurLines);
  finally
    LAuto.Free;
  end;
end;

procedure TRollingCountTextFileSink.Flush;
begin
  if FOpened then
  begin
    {$IFDEF WINDOWS}
    FlushFileBuffers(THandle(FStream.Handle));
    {$ELSE}
    fpfsync(FStream.Handle);
    {$ENDIF}
  end;
end;

end.

