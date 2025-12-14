unit fafafa.core.io.instrument;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.instrument - I/O 观测与诊断

  提供：
  - TIOEvent: I/O 事件记录
  - TIOEventKind: 事件类型枚举
  - TInstrumentedReader/Writer: 带观测的包装器

  用于监控、计时、调试 I/O 操作。

  参考: Rust tracing, Go io.TeeReader 思想扩展
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TIOEventKind - I/O 事件类型 }
  TIOEventKind = (
    iekRead,    // 读取操作
    iekWrite,   // 写入操作
    iekSeek,    // 定位操作
    iekFlush,   // 刷新操作
    iekClose    // 关闭操作
  );

  { TIOEvent - I/O 事件记录

    包含操作类型、字节数、耗时、错误信息等。
  }
  TIOEvent = record
    Kind: TIOEventKind;     // 事件类型
    Bytes: SizeInt;         // 操作的字节数（Read/Write）
    Position: Int64;        // 当前位置（Seek 后）
    ElapsedMs: Double;      // 操作耗时（毫秒）
    Error: Exception;       // 异常（如果有）
    Timestamp: TDateTime;   // 事件时间戳
  end;

  { TIOEventProc - 事件回调类型 }
  TIOEventProc = procedure(const Event: TIOEvent) of object;
  TIOEventProcNested = procedure(const Event: TIOEvent) is nested;

  { TInstrumentedReader - 带观测的读取器包装

    包装一个 IReader，在每次操作后触发事件回调。
    支持计时和错误捕获。

    用法：
      IR := InstrumentReader(SomeReader, @OnIOEvent);
      try
        N := IR.Read(@Buf, Size);  // 触发 OnIOEvent
      finally
        IR.Free;
      end;
  }
  TInstrumentedReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FOnEvent: TIOEventProc;
    FOnEventNested: TIOEventProcNested;
    procedure FireEvent(Kind: TIOEventKind; Bytes: SizeInt; Position: Int64;
      ElapsedMs: Double; Error: Exception);
  public
    constructor Create(AInner: IReader; AOnEvent: TIOEventProc); overload;
    constructor Create(AInner: IReader; AOnEvent: TIOEventProcNested); overload;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TInstrumentedWriter - 带观测的写入器包装

    包装一个 IWriter，在每次操作后触发事件回调。
  }
  TInstrumentedWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FOnEvent: TIOEventProc;
    FOnEventNested: TIOEventProcNested;
    procedure FireEvent(Kind: TIOEventKind; Bytes: SizeInt; Position: Int64;
      ElapsedMs: Double; Error: Exception);
  public
    constructor Create(AInner: IWriter; AOnEvent: TIOEventProc); overload;
    constructor Create(AInner: IWriter; AOnEvent: TIOEventProcNested); overload;

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TInstrumentedReadSeeker - 带观测的可定位读取器包装 }
  TInstrumentedReadSeeker = class(TInterfacedObject, IReader, ISeeker, IReadSeeker)
  private
    FInner: IReadSeeker;
    FOnEvent: TIOEventProc;
    FOnEventNested: TIOEventProcNested;
    procedure FireEvent(Kind: TIOEventKind; Bytes: SizeInt; Position: Int64;
      ElapsedMs: Double; Error: Exception);
  public
    constructor Create(AInner: IReadSeeker; AOnEvent: TIOEventProc); overload;
    constructor Create(AInner: IReadSeeker; AOnEvent: TIOEventProcNested); overload;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { ISeeker }
    function Seek(Offset: Int64; Whence: Integer): Int64;
  end;

{ 工厂函数 }
function InstrumentReader(AInner: IReader; AOnEvent: TIOEventProc): IReader; overload;
function InstrumentReader(AInner: IReader; AOnEvent: TIOEventProcNested): IReader; overload;
function InstrumentWriter(AInner: IWriter; AOnEvent: TIOEventProc): IWriter; overload;
function InstrumentWriter(AInner: IWriter; AOnEvent: TIOEventProcNested): IWriter; overload;
function InstrumentReadSeeker(AInner: IReadSeeker; AOnEvent: TIOEventProc): IReadSeeker; overload;
function InstrumentReadSeeker(AInner: IReadSeeker; AOnEvent: TIOEventProcNested): IReadSeeker; overload;

{ 辅助函数 }
function IOEventKindToStr(Kind: TIOEventKind): string;

implementation

uses
  DateUtils;

function GetTickMs: Double;
begin
  Result := Now * 24 * 60 * 60 * 1000;  // 简单实现，精度到毫秒
end;

function IOEventKindToStr(Kind: TIOEventKind): string;
begin
  case Kind of
    iekRead:  Result := 'read';
    iekWrite: Result := 'write';
    iekSeek:  Result := 'seek';
    iekFlush: Result := 'flush';
    iekClose: Result := 'close';
  end;
end;

{ TInstrumentedReader }

constructor TInstrumentedReader.Create(AInner: IReader; AOnEvent: TIOEventProc);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := AOnEvent;
  FOnEventNested := nil;
end;

constructor TInstrumentedReader.Create(AInner: IReader; AOnEvent: TIOEventProcNested);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := nil;
  FOnEventNested := AOnEvent;
end;

procedure TInstrumentedReader.FireEvent(Kind: TIOEventKind; Bytes: SizeInt;
  Position: Int64; ElapsedMs: Double; Error: Exception);
var
  Evt: TIOEvent;
begin
  Evt.Kind := Kind;
  Evt.Bytes := Bytes;
  Evt.Position := Position;
  Evt.ElapsedMs := ElapsedMs;
  Evt.Error := Error;
  Evt.Timestamp := Now;

  if Assigned(FOnEvent) then
    FOnEvent(Evt)
  else if Assigned(FOnEventNested) then
    FOnEventNested(Evt);
end;

function TInstrumentedReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  StartMs, EndMs: Double;
  Err: Exception;
begin
  StartMs := GetTickMs;
  Err := nil;
  try
    Result := FInner.Read(Buf, Count);
  except
    on E: Exception do
    begin
      Err := E;
      raise;
    end;
  end;
  EndMs := GetTickMs;
  FireEvent(iekRead, Result, -1, EndMs - StartMs, Err);
end;

{ TInstrumentedWriter }

constructor TInstrumentedWriter.Create(AInner: IWriter; AOnEvent: TIOEventProc);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := AOnEvent;
  FOnEventNested := nil;
end;

constructor TInstrumentedWriter.Create(AInner: IWriter; AOnEvent: TIOEventProcNested);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := nil;
  FOnEventNested := AOnEvent;
end;

procedure TInstrumentedWriter.FireEvent(Kind: TIOEventKind; Bytes: SizeInt;
  Position: Int64; ElapsedMs: Double; Error: Exception);
var
  Evt: TIOEvent;
begin
  Evt.Kind := Kind;
  Evt.Bytes := Bytes;
  Evt.Position := Position;
  Evt.ElapsedMs := ElapsedMs;
  Evt.Error := Error;
  Evt.Timestamp := Now;

  if Assigned(FOnEvent) then
    FOnEvent(Evt)
  else if Assigned(FOnEventNested) then
    FOnEventNested(Evt);
end;

function TInstrumentedWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  StartMs, EndMs: Double;
  Err: Exception;
begin
  StartMs := GetTickMs;
  Err := nil;
  try
    Result := FInner.Write(Buf, Count);
  except
    on E: Exception do
    begin
      Err := E;
      raise;
    end;
  end;
  EndMs := GetTickMs;
  FireEvent(iekWrite, Result, -1, EndMs - StartMs, Err);
end;

{ TInstrumentedReadSeeker }

constructor TInstrumentedReadSeeker.Create(AInner: IReadSeeker; AOnEvent: TIOEventProc);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := AOnEvent;
  FOnEventNested := nil;
end;

constructor TInstrumentedReadSeeker.Create(AInner: IReadSeeker; AOnEvent: TIOEventProcNested);
begin
  inherited Create;
  FInner := AInner;
  FOnEvent := nil;
  FOnEventNested := AOnEvent;
end;

procedure TInstrumentedReadSeeker.FireEvent(Kind: TIOEventKind; Bytes: SizeInt;
  Position: Int64; ElapsedMs: Double; Error: Exception);
var
  Evt: TIOEvent;
begin
  Evt.Kind := Kind;
  Evt.Bytes := Bytes;
  Evt.Position := Position;
  Evt.ElapsedMs := ElapsedMs;
  Evt.Error := Error;
  Evt.Timestamp := Now;

  if Assigned(FOnEvent) then
    FOnEvent(Evt)
  else if Assigned(FOnEventNested) then
    FOnEventNested(Evt);
end;

function TInstrumentedReadSeeker.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  StartMs, EndMs: Double;
  Err: Exception;
begin
  StartMs := GetTickMs;
  Err := nil;
  try
    Result := FInner.Read(Buf, Count);
  except
    on E: Exception do
    begin
      Err := E;
      raise;
    end;
  end;
  EndMs := GetTickMs;
  FireEvent(iekRead, Result, -1, EndMs - StartMs, Err);
end;

function TInstrumentedReadSeeker.Seek(Offset: Int64; Whence: Integer): Int64;
var
  StartMs, EndMs: Double;
  Err: Exception;
begin
  StartMs := GetTickMs;
  Err := nil;
  try
    Result := FInner.Seek(Offset, Whence);
  except
    on E: Exception do
    begin
      Err := E;
      raise;
    end;
  end;
  EndMs := GetTickMs;
  FireEvent(iekSeek, 0, Result, EndMs - StartMs, Err);
end;

{ 工厂函数 }

function InstrumentReader(AInner: IReader; AOnEvent: TIOEventProc): IReader;
begin
  Result := TInstrumentedReader.Create(AInner, AOnEvent);
end;

function InstrumentReader(AInner: IReader; AOnEvent: TIOEventProcNested): IReader;
begin
  Result := TInstrumentedReader.Create(AInner, AOnEvent);
end;

function InstrumentWriter(AInner: IWriter; AOnEvent: TIOEventProc): IWriter;
begin
  Result := TInstrumentedWriter.Create(AInner, AOnEvent);
end;

function InstrumentWriter(AInner: IWriter; AOnEvent: TIOEventProcNested): IWriter;
begin
  Result := TInstrumentedWriter.Create(AInner, AOnEvent);
end;

function InstrumentReadSeeker(AInner: IReadSeeker; AOnEvent: TIOEventProc): IReadSeeker;
begin
  Result := TInstrumentedReadSeeker.Create(AInner, AOnEvent);
end;

function InstrumentReadSeeker(AInner: IReadSeeker; AOnEvent: TIOEventProcNested): IReadSeeker;
begin
  Result := TInstrumentedReadSeeker.Create(AInner, AOnEvent);
end;

end.
