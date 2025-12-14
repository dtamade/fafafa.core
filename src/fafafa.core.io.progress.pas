unit fafafa.core.io.progress;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.progress - 进度回调包装器

  提供读写时的进度回调功能，支持：
  - 已处理字节数
  - 总字节数（可选）
  - 百分比计算

  用法:
    var R: IReader;
    begin
      R := IO.Progress(IO.OpenRead('large.dat'), procedure(const E: TProgressEvent)
      begin
        WriteLn(Format('Progress: %.1f%%', [E.Percent]));
      end, FileSize);
    end;
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TProgressEvent - 进度事件数据 }
  TProgressEvent = record
    BytesProcessed: Int64;  // 累计已处理字节数
    TotalBytes: Int64;      // 总字节数（-1 表示未知）
    Percent: Double;        // 百分比（TotalBytes 未知时为 -1）
  end;

  { TProgressCallback - 进度回调 }
  TProgressCallback = procedure(const AEvent: TProgressEvent) is nested;

  { TProgressReader - 带进度回调的读取器 }
  TProgressReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FCallback: TProgressCallback;
    FBytesRead: Int64;
    FTotal: Int64;
  public
    constructor Create(AInner: IReader; ACallback: TProgressCallback; ATotal: Int64 = -1);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TProgressWriter - 带进度回调的写入器 }
  TProgressWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FCallback: TProgressCallback;
    FBytesWritten: Int64;
    FTotal: Int64;
  public
    constructor Create(AInner: IWriter; ACallback: TProgressCallback; ATotal: Int64 = -1);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 工厂函数 }
function ProgressReader(AInner: IReader; ACallback: TProgressCallback; ATotal: Int64 = -1): IReader;
function ProgressWriter(AInner: IWriter; ACallback: TProgressCallback; ATotal: Int64 = -1): IWriter;

implementation

{ TProgressReader }

constructor TProgressReader.Create(AInner: IReader; ACallback: TProgressCallback; ATotal: Int64);
begin
  inherited Create;
  FInner := AInner;
  FCallback := ACallback;
  FBytesRead := 0;
  FTotal := ATotal;
end;

function TProgressReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Event: TProgressEvent;
begin
  Result := FInner.Read(Buf, Count);
  if Result > 0 then
  begin
    Inc(FBytesRead, Result);
    Event.BytesProcessed := FBytesRead;
    Event.TotalBytes := FTotal;
    if FTotal > 0 then
      Event.Percent := (FBytesRead * 100.0) / FTotal
    else
      Event.Percent := -1;
    FCallback(Event);
  end;
end;

{ TProgressWriter }

constructor TProgressWriter.Create(AInner: IWriter; ACallback: TProgressCallback; ATotal: Int64);
begin
  inherited Create;
  FInner := AInner;
  FCallback := ACallback;
  FBytesWritten := 0;
  FTotal := ATotal;
end;

function TProgressWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Event: TProgressEvent;
begin
  Result := FInner.Write(Buf, Count);
  if Result > 0 then
  begin
    Inc(FBytesWritten, Result);
    Event.BytesProcessed := FBytesWritten;
    Event.TotalBytes := FTotal;
    if FTotal > 0 then
      Event.Percent := (FBytesWritten * 100.0) / FTotal
    else
      Event.Percent := -1;
    FCallback(Event);
  end;
end;

{ 工厂函数 }

function ProgressReader(AInner: IReader; ACallback: TProgressCallback; ATotal: Int64): IReader;
begin
  Result := TProgressReader.Create(AInner, ACallback, ATotal);
end;

function ProgressWriter(AInner: IWriter; ACallback: TProgressCallback; ATotal: Int64): IWriter;
begin
  Result := TProgressWriter.Create(AInner, ACallback, ATotal);
end;

end.
