unit fafafa.core.io.adapters;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.adapters - IO 适配器

  提供：
  - TNopCloser: 将 IReader 包装为 IReadCloser（空 Close）
  - TChainReader: 串联两个 Reader
  - TSkipReader: 跳过前 N 字节

  参考: Go io.NopCloser, Rust std::io::Chain
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TNopCloser - 空关闭包装器

    将 IReader 包装为 IReadCloser，Close 操作为空。
    适用于需要 IReadCloser 但底层流不需要关闭的场景。

    用法：
      RC := NopCloser(SomeReader);
      // 使用 RC...
      RC.Close;  // 安全，不做任何事
  }
  TNopCloser = class(TInterfacedObject, IReader, ICloser, IReadCloser)
  private
    FInner: IReader;
  public
    constructor Create(AInner: IReader);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { ICloser }
    procedure Close;
  end;

  { TChainReader - 串联两个 Reader

    先从 First 读取直到 EOF，然后从 Second 读取。
    类似 Rust std::io::Chain。

    用法：
      Chained := Chain(Reader1, Reader2);
      // 先读 Reader1，EOF 后自动读 Reader2
  }
  TChainReader = class(TInterfacedObject, IReader)
  private
    FFirst: IReader;
    FSecond: IReader;
    FFirstDone: Boolean;
  public
    constructor Create(AFirst, ASecond: IReader);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TSkipReader - 跳过前 N 字节

    在第一次读取时跳过（丢弃）前 N 字节。
    适用于跳过文件头、前缀等场景。

    用法：
      Skipped := Skip(SomeReader, 100);  // 跳过前 100 字节
  }
  TSkipReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FSkip: Int64;
    FSkipped: Boolean;
  public
    constructor Create(AInner: IReader; ASkip: Int64);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 工厂函数 }
function NopCloser(AInner: IReader): IReadCloser;
function Chain(AFirst, ASecond: IReader): IReader;
function Skip(AInner: IReader; N: Int64): IReader;

implementation

{ TNopCloser }

constructor TNopCloser.Create(AInner: IReader);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TNopCloser: inner reader is nil');
  FInner := AInner;
end;

function TNopCloser.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Read(Buf, Count);
end;

procedure TNopCloser.Close;
begin
  // 空操作
end;

{ TChainReader }

constructor TChainReader.Create(AFirst, ASecond: IReader);
begin
  inherited Create;
  FFirst := AFirst;
  FSecond := ASecond;
  FFirstDone := False;
end;

function TChainReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 先从 First 读取
  if not FFirstDone then
  begin
    if FFirst <> nil then
      Result := FFirst.Read(Buf, Count);

    if Result > 0 then
      Exit;

    // First EOF，切换到 Second
    FFirstDone := True;
  end;

  // 从 Second 读取
  if FSecond <> nil then
    Result := FSecond.Read(Buf, Count);
end;

{ 工厂函数 }

function NopCloser(AInner: IReader): IReadCloser;
begin
  Result := TNopCloser.Create(AInner);
end;

function Chain(AFirst, ASecond: IReader): IReader;
begin
  Result := TChainReader.Create(AFirst, ASecond);
end;

function Skip(AInner: IReader; N: Int64): IReader;
begin
  Result := TSkipReader.Create(AInner, N);
end;

{ TSkipReader }

constructor TSkipReader.Create(AInner: IReader; ASkip: Int64);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TSkipReader: inner reader is nil');
  FInner := AInner;
  if ASkip < 0 then
    ASkip := 0;
  FSkip := ASkip;
  FSkipped := False;
end;

function TSkipReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  LBuf: array[0..4095] of Byte;  // 4KB 临时缓冲区
  LToSkip, LRead: SizeInt;
  LSeeker: ISeeker;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 首次读取时跳过前 N 字节
  if not FSkipped then
  begin
    // 优化：如果底层支持 Seek，直接定位
    if (FSkip > 0) and Supports(FInner, ISeeker, LSeeker) then
    begin
      try
        LSeeker.Seek(FSkip, SeekCurrent);
        FSkip := 0;
      except
        // Seek 失败（例如非 Seekable 流误报），降级到普通读取
        on E: Exception do ;
      end;
    end;

    while FSkip > 0 do
    begin
      if FSkip > SizeOf(LBuf) then
        LToSkip := SizeOf(LBuf)
      else
        LToSkip := FSkip;

      try
        LRead := FInner.Read(@LBuf[0], LToSkip);
      except
        on E: EIOError do
        begin
          if E.Kind = ekInterrupted then
            Continue;
          raise;
        end;
      end;
      if LRead = 0 then
        Break;  // EOF

      Dec(FSkip, LRead);
    end;
    FSkipped := True;
  end;

  // 正常读取
  Result := FInner.Read(Buf, Count);
end;

end.
