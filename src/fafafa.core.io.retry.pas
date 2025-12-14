unit fafafa.core.io.retry;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.retry - 自动重试包装器

  提供：
  - TRetryReader: 带自动重试的读取器
  - TRetryWriter: 带自动重试的写入器

  只有 IOErrorRetryable 返回 true 的错误类型才会重试：
  - ekInterrupted: 被中断
  - ekTimedOut: 超时
  - ekWouldBlock: 会阻塞
}

interface

uses
  SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.error;

type
  { TRetryReader - 带自动重试的读取器包装

    当底层 Read 抛出可重试错误时，自动重试直到成功或达到最大次数。
    不可重试的错误会立即向上传播。
  }
  TRetryReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FMaxAttempts: Integer;
    FDelayMs: Integer;
  public
    { 构造函数
      AInner: 底层读取器
      AMaxAttempts: 最大尝试次数（包括首次）
      ADelayMs: 重试间隔（毫秒），0 表示不等待
    }
    constructor Create(AInner: IReader; AMaxAttempts: Integer; ADelayMs: Integer = 100);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TRetryWriter - 带自动重试的写入器包装

    当底层 Write 抛出可重试错误时，自动重试直到成功或达到最大次数。
    不可重试的错误会立即向上传播。
  }
  TRetryWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FMaxAttempts: Integer;
    FDelayMs: Integer;
  public
    { 构造函数
      AInner: 底层写入器
      AMaxAttempts: 最大尝试次数（包括首次）
      ADelayMs: 重试间隔（毫秒），0 表示不等待
    }
    constructor Create(AInner: IWriter; AMaxAttempts: Integer; ADelayMs: Integer = 100);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 便捷工厂函数 }
function RetryReader(AInner: IReader; AMaxAttempts: Integer; ADelayMs: Integer = 100): IReader;
function RetryWriter(AInner: IWriter; AMaxAttempts: Integer; ADelayMs: Integer = 100): IWriter;

implementation

{ TRetryReader }

constructor TRetryReader.Create(AInner: IReader; AMaxAttempts: Integer; ADelayMs: Integer);
begin
  inherited Create;
  FInner := AInner;
  FMaxAttempts := AMaxAttempts;
  if FMaxAttempts < 1 then
    FMaxAttempts := 1;
  FDelayMs := ADelayMs;
end;

function TRetryReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Attempt: Integer;
begin
  Attempt := 0;
  
  while Attempt < FMaxAttempts do
  begin
    Inc(Attempt);
    try
      Result := FInner.Read(Buf, Count);
      Exit;  // 成功，返回
    except
      on E: EIOError do
      begin
        // 不可重试的错误，立即传播
        if not IOErrorRetryable(E.Kind) then
          raise;
        
        // 已达最大尝试次数
        if Attempt >= FMaxAttempts then
          raise;
        
        // 等待后重试
        if FDelayMs > 0 then
          Sleep(FDelayMs);
      end;
    end;
  end;
  
  // 理论上不应到达这里
  Result := 0;
end;

{ TRetryWriter }

constructor TRetryWriter.Create(AInner: IWriter; AMaxAttempts: Integer; ADelayMs: Integer);
begin
  inherited Create;
  FInner := AInner;
  FMaxAttempts := AMaxAttempts;
  if FMaxAttempts < 1 then
    FMaxAttempts := 1;
  FDelayMs := ADelayMs;
end;

function TRetryWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Attempt: Integer;
begin
  Attempt := 0;
  
  while Attempt < FMaxAttempts do
  begin
    Inc(Attempt);
    try
      Result := FInner.Write(Buf, Count);
      Exit;  // 成功，返回
    except
      on E: EIOError do
      begin
        // 不可重试的错误，立即传播
        if not IOErrorRetryable(E.Kind) then
          raise;
        
        // 已达最大尝试次数
        if Attempt >= FMaxAttempts then
          raise;
        
        // 等待后重试
        if FDelayMs > 0 then
          Sleep(FDelayMs);
      end;
    end;
  end;
  
  // 理论上不应到达这里
  Result := 0;
end;

{ 便捷工厂函数 }

function RetryReader(AInner: IReader; AMaxAttempts: Integer; ADelayMs: Integer): IReader;
begin
  Result := TRetryReader.Create(AInner, AMaxAttempts, ADelayMs);
end;

function RetryWriter(AInner: IWriter; AMaxAttempts: Integer; ADelayMs: Integer): IWriter;
begin
  Result := TRetryWriter.Create(AInner, AMaxAttempts, ADelayMs);
end;

end.
