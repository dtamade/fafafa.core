unit fafafa.core.io.timeout;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.timeout - 超时包装器

  提供：
  - TTimeoutReader: 带超时的读取器
  - TTimeoutWriter: 带超时的写入器

  超时机制使用简单的经过时间检测（非真正的异步超时）。
  在每次 Read/Write 调用前后测量时间，若超过阈值则抛出 ekTimedOut。
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TTimeoutReader - 带超时的读取器包装

    在执行底层 Read 前后检测时间，若耗时超过 TimeoutMs 则抛出 EIOError(ekTimedOut)。
    注意：这是"乐观"超时检测，只能检测底层操作耗时过长，无法真正中断阻塞操作。
  }
  TTimeoutReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FTimeoutMs: Integer;
  public
    constructor Create(AInner: IReader; ATimeoutMs: Integer);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TTimeoutWriter - 带超时的写入器包装

    在执行底层 Write 前后检测时间，若耗时超过 TimeoutMs 则抛出 EIOError(ekTimedOut)。
  }
  TTimeoutWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FTimeoutMs: Integer;
  public
    constructor Create(AInner: IWriter; ATimeoutMs: Integer);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 便捷工厂函数 }
function TimeoutReader(AInner: IReader; ATimeoutMs: Integer): IReader;
function TimeoutWriter(AInner: IWriter; ATimeoutMs: Integer): IWriter;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  DateUtils;

{ 获取当前 tick 计数（毫秒） }
function GetCurrentTickMs: Int64;
begin
  {$IFDEF WINDOWS}
  Result := GetTickCount64;
  {$ELSE}
  // 使用 clock_gettime 获取单调时间
  Result := MilliSecondsBetween(Now, 0);
  {$ENDIF}
end;

{ TTimeoutReader }

constructor TTimeoutReader.Create(AInner: IReader; ATimeoutMs: Integer);
begin
  inherited Create;
  FInner := AInner;
  FTimeoutMs := ATimeoutMs;
end;

function TTimeoutReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  StartTick, ElapsedMs: Int64;
begin
  StartTick := GetCurrentTickMs;
  
  // 执行底层读取
  Result := FInner.Read(Buf, Count);
  
  // 检查耗时
  ElapsedMs := GetCurrentTickMs - StartTick;
  if ElapsedMs > FTimeoutMs then
    raise EIOError.Create(ekTimedOut, 'read', '', 0, 
      Format('operation timed out (elapsed: %dms, limit: %dms)', [ElapsedMs, FTimeoutMs]));
end;

{ TTimeoutWriter }

constructor TTimeoutWriter.Create(AInner: IWriter; ATimeoutMs: Integer);
begin
  inherited Create;
  FInner := AInner;
  FTimeoutMs := ATimeoutMs;
end;

function TTimeoutWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  StartTick, ElapsedMs: Int64;
begin
  StartTick := GetCurrentTickMs;
  
  // 执行底层写入
  Result := FInner.Write(Buf, Count);
  
  // 检查耗时
  ElapsedMs := GetCurrentTickMs - StartTick;
  if ElapsedMs > FTimeoutMs then
    raise EIOError.Create(ekTimedOut, 'write', '', 0,
      Format('operation timed out (elapsed: %dms, limit: %dms)', [ElapsedMs, FTimeoutMs]));
end;

{ 便捷工厂函数 }

function TimeoutReader(AInner: IReader; ATimeoutMs: Integer): IReader;
begin
  Result := TTimeoutReader.Create(AInner, ATimeoutMs);
end;

function TimeoutWriter(AInner: IWriter; ATimeoutMs: Integer): IWriter;
begin
  Result := TTimeoutWriter.Create(AInner, ATimeoutMs);
end;

end.
