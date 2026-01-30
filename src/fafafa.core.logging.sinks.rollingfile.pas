unit fafafa.core.logging.sinks.rollingfile;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.io,
  fafafa.core.logging.interfaces
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFDEF UNIX}, BaseUnix{$ENDIF}
  ;

type
  { 基于大小滚动的文本文件 Sink（简单版） }
  TRollingTextFileSink = class(TInterfacedObject, ITextSink)
  private
    FPath: string;
    FMaxBytes: QWord;
    FCurBytes: QWord; // 已持久化到文件的字节数（不含缓冲）
    FStream: TFileStream;
    FOpened: Boolean;
    FLock: ILock;
    FMaxFiles: Integer; // 0 表示不清理历史
    FMaxTotalBytes: QWord; // 0 表示不限制总大小（仅 MaxFiles 生效）
    // 可选写缓冲（默认禁用）：聚合 UTF-8 + EOL，减少 Write 调用次数
    FBuf: RawByteString;
    FBufCap: Integer; // 0 表示禁用缓冲
  private
    procedure EnsureOpen;
    procedure Rotate;
    procedure CleanupOldFiles;
    function FileSizeOf(const FullPath: string): QWord;
    function NewRollName: string;
    procedure FlushBufferToFile;
  public
    constructor Create(const APath: string; const AMaxBytes: QWord; const AMaxFiles: Integer = 0; const AMaxTotalBytes: QWord = 0; const ABufferBytes: Integer = 0);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

constructor TRollingTextFileSink.Create(const APath: string; const AMaxBytes: QWord; const AMaxFiles: Integer; const AMaxTotalBytes: QWord; const ABufferBytes: Integer);
begin
  inherited Create;
  if APath = '' then raise EArgumentException.Create('path');
  if AMaxBytes = 0 then raise EArgumentException.Create('maxBytes');
  FPath := APath;
  FMaxBytes := AMaxBytes;
  FCurBytes := 0;
  FOpened := False;
  FLock := TMutex.Create;
  if AMaxFiles < 0 then FMaxFiles := 0 else FMaxFiles := AMaxFiles;
  FMaxTotalBytes := AMaxTotalBytes;
  FBuf := '';
  if ABufferBytes < 0 then FBufCap := 0 else FBufCap := ABufferBytes;
end;

destructor TRollingTextFileSink.Destroy;
begin
  if FOpened then
  begin
    FreeAndNil(FStream);
    FOpened := False;
  end;
  inherited Destroy;
end;

procedure TRollingTextFileSink.EnsureOpen;
begin
  if not FOpened then
  begin
    if FileExists(FPath) then
    begin
      FStream := TFileStream.Create(FPath, fmOpenReadWrite or fmShareDenyNone);
      FStream.Seek(0, soEnd);
    end
    else
    begin
      FStream := TFileStream.Create(FPath, fmCreate or fmShareDenyNone);
    end;
    FOpened := True;
    // 初始化当前大小为实际文件大小
    try
      FCurBytes := QWord(FStream.Size);
    except
      FCurBytes := 0;
    end;
  end;
end;

function TRollingTextFileSink.NewRollName: string;
var ts: string; base, ext: string;
begin
  ts := FormatDateTime('yyyymmdd_hhnnss_zzz', Now);
  base := FPath;
  ext := '';
  // 采用带前缀的命名，便于清理只识别本类型：BaseName.size-TS
  Result := base + '.size-' + ts;
end;

function TRollingTextFileSink.FileSizeOf(const FullPath: string): QWord;
var FS: TFileStream;
begin
  Result := 0;
  if not FileExists(FullPath) then Exit(0);
  FS := TFileStream.Create(FullPath, fmOpenRead or fmShareDenyNone);
  try
    Result := QWord(FS.Seek(0, soEnd));
  finally
    FS.Free;
  end;
end;

procedure TRollingTextFileSink.CleanupOldFiles;
var
  Dir, BaseName, Mask: string;
  SR: TSearchRec;
  Files: TStringList;
  Sizes: array of QWord;
  I: Integer;
  FN, Full: string;
  Total: QWord;
begin
  if (FMaxFiles <= 0) and (FMaxTotalBytes = 0) then Exit;
  Dir := ExtractFilePath(FPath);
  BaseName := ExtractFileName(FPath);
  if Dir = '' then Dir := '.' + DirectorySeparator;
  // 仅匹配 size-based 滚动生成的文件：BaseName.size-*
  Mask := BaseName + '.size-*';
  Files := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(Dir)+Mask, faAnyFile and not faDirectory, SR) = 0 then
    begin
      repeat
        FN := SR.Name;
        if Pos(BaseName + '.', FN) = 1 then
          Files.Add(FN);
      until FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
    Files.Sort;

    // 先满足 MaxFiles 约束
    while (FMaxFiles > 0) and (Files.Count > FMaxFiles) do
    begin
      SysUtils.DeleteFile(IncludeTrailingPathDelimiter(Dir) + Files[0]);
      Files.Delete(0);
    end;

    // 再考虑总大小约束（如果开启）
    if FMaxTotalBytes > 0 then
    begin
      SetLength(Sizes, Files.Count);
      Total := 0;
      for I := 0 to Files.Count - 1 do
      begin
        Full := IncludeTrailingPathDelimiter(Dir) + Files[I];
        Sizes[I] := FileSizeOf(Full);
        Inc(Total, Sizes[I]);
      end;
      I := 0;
      while (I < Files.Count) and (Total > FMaxTotalBytes) do
      begin
        Full := IncludeTrailingPathDelimiter(Dir) + Files[I];
        if SysUtils.DeleteFile(Full) then
        begin
          Dec(Total, Sizes[I]);
          Files.Delete(I);
        end
        else
          Inc(I);
      end;
    end;
  finally
    Files.Free;
  end;
end;

procedure TRollingTextFileSink.Rotate;
var newName: string;
begin
  // 约定：调用方在必要时已处理缓冲（将缓冲冲刷到合适的目标文件或清空）
  if FOpened then
  begin
    FreeAndNil(FStream);
    FOpened := False;
  end;
  newName := NewRollName;
  // 若重名，附加随机后缀（极小概率）
  if FileExists(FPath) then
  begin
    if not RenameFile(FPath, newName) then
      RenameFile(FPath, newName + '.' + IntToHex(Random(MaxInt), 8));
  end;
  // 清理历史（若启用）
  CleanupOldFiles;
  FCurBytes := 0;
  EnsureOpen;
end;

procedure TRollingTextFileSink.FlushBufferToFile;
begin
  if (FBufCap > 0) and (Length(FBuf) > 0) then
  begin
    FStream.WriteBuffer(FBuf[1], Length(FBuf));
    Inc(FCurBytes, QWord(Length(FBuf)));
    SetLength(FBuf, 0);
  end;
end;

procedure TRollingTextFileSink.WriteLine(const S: string);
var
  bytesNeeded: QWord;
  LAuto: TAutoLock;
  U: UTF8String;
  needRotate: Boolean;
  curBuffered: QWord;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    EnsureOpen;
    // 以 UTF-8 字节长度 + 平台换行符字节数 估算
    U := UTF8String(S);
    bytesNeeded := QWord(Length(U)) + QWord(Length(LineEnding));

    if FBufCap <= 0 then
    begin
      // 原始路径：无缓冲
      if (FCurBytes + bytesNeeded) > FMaxBytes then
      begin
        // 接近阈值时做一次真实大小校准，避免估算误差
        FCurBytes := FileSizeOf(FPath);
        if (FCurBytes + bytesNeeded) > FMaxBytes then
        begin
          Rotate;
          EnsureOpen;
        end;
      end;
      if Length(U) > 0 then
        FStream.WriteBuffer(U[1], Length(U));
      if Length(LineEnding) > 0 then
        FStream.WriteBuffer(LineEnding[1], Length(LineEnding));
      Inc(FCurBytes, bytesNeeded);
      Exit;
    end;

    // 缓冲路径：考虑缓冲中的待写字节
    curBuffered := QWord(Length(FBuf));
    needRotate := (FCurBytes + curBuffered + bytesNeeded) > FMaxBytes;
    if needRotate then
    begin
      // 校准一次真实文件大小（不含缓冲）
      FCurBytes := FileSizeOf(FPath);
      curBuffered := QWord(Length(FBuf));
      needRotate := (FCurBytes + curBuffered + bytesNeeded) > FMaxBytes;
      if needRotate then
      begin
        // 优先冲刷缓冲（如能放得下）
        if (curBuffered > 0) and ((FCurBytes + curBuffered) <= FMaxBytes) then
        begin
          FlushBufferToFile;
          curBuffered := 0;
        end;
        // 若仍会越界，则旋转后在新文件写入
        if (FCurBytes + curBuffered + bytesNeeded) > FMaxBytes then
        begin
          Rotate;
          EnsureOpen;
        end;
      end;
    end;

    // 将当前行追加进缓冲
    if Length(U) > 0 then
    begin
      SetLength(FBuf, Length(FBuf) + Length(U));
      Move(U[1], FBuf[Length(FBuf) - Length(U) + 1], Length(U));
    end;
    if Length(LineEnding) > 0 then
    begin
      SetLength(FBuf, Length(FBuf) + Length(LineEnding));
      Move(LineEnding[1], FBuf[Length(FBuf) - Length(LineEnding) + 1], Length(LineEnding));
    end;

    // 如果缓冲达到容量则写入
    if Length(FBuf) >= FBufCap then
      FlushBufferToFile;
  finally
    LAuto.Free;
  end;
end;

procedure TRollingTextFileSink.Flush;
var
  LAuto: TAutoLock;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    if FOpened then
    begin
      // 冲刷缓冲后再落盘
      FlushBufferToFile;
      {$IFDEF WINDOWS}
      FlushFileBuffers(THandle(FStream.Handle));
      {$ELSE}
      fpfsync(FStream.Handle);
      {$ENDIF}
    end;
  finally
    LAuto.Free;
  end;
end;

end.

