unit fafafa.core.io.buffered;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.buffered - 缓冲 IO 实现

  提供：
  - TBufReader: 带缓冲的读取器包装
  - TBufWriter: 带缓冲的写入器包装

  参考: Rust std::io::BufReader / BufWriter
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

const
  DefaultBufSize = 8192;  // 默认缓冲区大小 8KB

type
  { TBufReader - 带缓冲读取器

    包装一个 IReader，提供内部缓冲区以减少系统调用次数。
    实现 IReader + IBufReader。

    用法：
      var BR: TBufReader;
      BR := TBufReader.Create(SomeReader);
      try
        while BR.ReadLine(Line) do
          ProcessLine(Line);
      finally
        BR.Free;
      end;
  }
  TBufReader = class(TInterfacedObject, IReader, IBufReader)
  private
    FInner: IReader;
    FBuf: TBytes;
    FPos: SizeInt;      // 当前读取位置
    FEnd: SizeInt;      // 有效数据结束位置
    FCapacity: SizeInt;
  public
    constructor Create(AInner: IReader; ABufSize: SizeInt = DefaultBufSize);
    destructor Destroy; override;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { IBufReader }
    function FillBuf(out Buf: PByte; out Len: SizeInt): Boolean;
    procedure Consume(N: SizeInt);
    function ReadLine(out Line: string): Boolean;
    function ReadUntil(Delim: Byte; out Data: TBytes): Boolean;

    { 额外方法 }
    function Inner: IReader;
    function Buffered: SizeInt; inline;  // 缓冲区中剩余字节数
  end;

  { TBufWriter - 带缓冲写入器

    包装一个 IWriter，提供内部缓冲区以减少系统调用次数。
    实现 IWriter + IFlusher。
    析构时自动 Flush。

    用法：
      var BW: TBufWriter;
      BW := TBufWriter.Create(SomeWriter);
      try
        BW.Write(@Data[0], Length(Data));
        BW.Flush;
      finally
        BW.Free;
      end;
  }
  TBufWriter = class(TInterfacedObject, IWriter, IFlusher)
  private
    FInner: IWriter;
    FBuf: TBytes;
    FPos: SizeInt;      // 当前写入位置
    FCapacity: SizeInt;
  public
    constructor Create(AInner: IWriter; ABufSize: SizeInt = DefaultBufSize);
    destructor Destroy; override;

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { IFlusher }
    procedure Flush;

    { 额外方法 }
    function Inner: IWriter;
    function Buffered: SizeInt; inline;  // 缓冲区中待写字节数
    function Available: SizeInt; inline; // 缓冲区剩余空间
  end;

implementation

{ TBufReader }

constructor TBufReader.Create(AInner: IReader; ABufSize: SizeInt);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TBufReader: inner reader is nil');
  if ABufSize <= 0 then
    ABufSize := DefaultBufSize;

  FInner := AInner;
  FCapacity := ABufSize;
  SetLength(FBuf, FCapacity);
  FPos := 0;
  FEnd := 0;
end;

destructor TBufReader.Destroy;
begin
  FInner := nil;
  SetLength(FBuf, 0);
  inherited Destroy;
end;

function TBufReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Available, ToCopy, DirectRead: SizeInt;
  P: PByte;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  P := PByte(Buf);

  // 1. 先从缓冲区读取
  Available := FEnd - FPos;
  if Available > 0 then
  begin
    ToCopy := Available;
    if ToCopy > Count then
      ToCopy := Count;
    Move(FBuf[FPos], P^, ToCopy);
    Inc(FPos, ToCopy);
    Inc(P, ToCopy);
    Inc(Result, ToCopy);
    Dec(Count, ToCopy);
  end;

  if Count = 0 then
    Exit;

  // 2. 如果请求量大于缓冲区容量，直接读取
  if Count >= FCapacity then
  begin
    DirectRead := FInner.Read(P, Count);
    Inc(Result, DirectRead);
    Exit;
  end;

  // 3. 重新填充缓冲区
  FPos := 0;

  while True do
  begin
    try
      FEnd := FInner.Read(@FBuf[0], FCapacity);
      Break;
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
  end;

  if FEnd <= 0 then
  begin
    FEnd := 0;
    Exit;
  end;

  // 4. 从新填充的缓冲区读取
  ToCopy := FEnd;
  if ToCopy > Count then
    ToCopy := Count;
  Move(FBuf[0], P^, ToCopy);
  FPos := ToCopy;
  Inc(Result, ToCopy);
end;

function TBufReader.FillBuf(out Buf: PByte; out Len: SizeInt): Boolean;
var
  N: SizeInt;
begin
  // 如果缓冲区为空，重新填充
  if FPos >= FEnd then
  begin
    FPos := 0;
    FEnd := 0;

    while True do
    begin
      try
        N := FInner.Read(@FBuf[0], FCapacity);
        Break;
      except
        on E: EIOError do
        begin
          if E.Kind = ekInterrupted then
            Continue;
          raise;
        end;
      end;
    end;

    if N > 0 then
      FEnd := N;
  end;

  Len := FEnd - FPos;
  if Len > 0 then
  begin
    Buf := @FBuf[FPos];
    Result := True;
  end
  else
  begin
    Buf := nil;
    Result := False;
  end;
end;

procedure TBufReader.Consume(N: SizeInt);
begin
  if N < 0 then
    N := 0;
  if N > FEnd - FPos then
    N := FEnd - FPos;
  Inc(FPos, N);
end;

function TBufReader.ReadLine(out Line: string): Boolean;
var
  Buf: PByte;
  Len, I, Start, LineLen: SizeInt;
  Builder: array of Char;
  BuilderLen, BuilderCap: SizeInt;
  HasCR: Boolean;
begin
  Line := '';
  Builder := nil;
  BuilderLen := 0;
  BuilderCap := 0;

  while True do
  begin
    if not FillBuf(Buf, Len) then
    begin
      // EOF
      if BuilderLen > 0 then
      begin
        SetString(Line, PChar(@Builder[0]), BuilderLen);
        Result := True;
      end
      else
        Result := False;
      Exit;
    end;

    // 在缓冲区中查找换行符
    Start := 0;
    for I := 0 to Len - 1 do
    begin
      if Buf[I] = 10 then  // LF
      begin
        LineLen := I - Start;

        // 处理 CRLF：两种情况
        // 1) CR 与 LF 在同一缓冲区内：...\r\n
        HasCR := (LineLen > 0) and (Buf[I - 1] = 13);
        if HasCR then
          Dec(LineLen);

        // 2) CR 在前一缓冲区末尾，LF 在本缓冲区开头：上一轮已经把 CR 放入 Builder
        if (not HasCR) and (I = 0) and (BuilderLen > 0) and (Builder[BuilderLen - 1] = #13) then
        begin
          Dec(BuilderLen); // 去掉末尾 CR
        end;

        // 追加当前缓冲区中的内容（不含行终止符）到 Builder
        if LineLen > 0 then
        begin
          if BuilderLen + LineLen > BuilderCap then
          begin
            BuilderCap := BuilderLen + LineLen + 256;
            SetLength(Builder, BuilderCap);
          end;
          Move(Buf[Start], Builder[BuilderLen], LineLen);
          Inc(BuilderLen, LineLen);
        end;

        Consume(I + 1);
        SetString(Line, PChar(@Builder[0]), BuilderLen);
        Result := True;
        Exit;
      end;
    end;

    // 没找到换行符，追加整个缓冲区并继续
    LineLen := Len;

    if BuilderLen + LineLen > BuilderCap then
    begin
      BuilderCap := BuilderLen + LineLen + 256;
      SetLength(Builder, BuilderCap);
    end;
    Move(Buf[0], Builder[BuilderLen], LineLen);
    Inc(BuilderLen, LineLen);

    Consume(Len);
  end;
end;

function TBufReader.ReadUntil(Delim: Byte; out Data: TBytes): Boolean;
var
  Buf: PByte;
  Len, I, DataLen, DataCap: SizeInt;
begin
  SetLength(Data, 0);
  DataLen := 0;
  DataCap := 0;

  while True do
  begin
    if not FillBuf(Buf, Len) then
    begin
      // EOF
      if DataLen > 0 then
      begin
        SetLength(Data, DataLen);
        Result := True;
      end
      else
        Result := False;
      Exit;
    end;

    // 在缓冲区中查找分隔符
    for I := 0 to Len - 1 do
    begin
      if Buf[I] = Delim then
      begin
        // 追加到 Data（包含分隔符）
        if DataLen + I + 1 > DataCap then
        begin
          DataCap := DataLen + I + 1;
          SetLength(Data, DataCap);
        end;
        Move(Buf[0], Data[DataLen], I + 1);
        Inc(DataLen, I + 1);
        SetLength(Data, DataLen);

        Consume(I + 1);
        Result := True;
        Exit;
      end;
    end;

    // 没找到分隔符，追加整个缓冲区并继续
    if DataLen + Len > DataCap then
    begin
      DataCap := DataLen + Len + 256;
      SetLength(Data, DataCap);
    end;
    Move(Buf[0], Data[DataLen], Len);
    Inc(DataLen, Len);

    Consume(Len);
  end;
end;

function TBufReader.Inner: IReader;
begin
  Result := FInner;
end;

function TBufReader.Buffered: SizeInt;
begin
  Result := FEnd - FPos;
end;

{ TBufWriter }

constructor TBufWriter.Create(AInner: IWriter; ABufSize: SizeInt);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TBufWriter: inner writer is nil');
  if ABufSize <= 0 then
    ABufSize := DefaultBufSize;

  FInner := AInner;
  FCapacity := ABufSize;
  SetLength(FBuf, FCapacity);
  FPos := 0;
end;

destructor TBufWriter.Destroy;
begin
  // 析构时自动 Flush
  if FPos > 0 then
  try
    Flush;
  except
    // 忽略析构时的错误
  end;
  FInner := nil;
  SetLength(FBuf, 0);
  inherited Destroy;
end;

function TBufWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  P: PByte;
  Space, ToCopy, Written: SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  P := PByte(Buf);

  // 1. 如果数据量大于缓冲区容量，先 Flush 再直接写
  if Count >= FCapacity then
  begin
    if FPos > 0 then
      Flush;
    while Count > 0 do
    begin
      while True do
      begin
        try
          Written := FInner.Write(P, Count);
          Break;
        except
          on E: EIOError do
          begin
            if E.Kind = ekInterrupted then
              Continue;
            raise;
          end;
        end;
      end;

      if Written = 0 then
        raise EIOError.Create(ekWriteZero, 'TBufWriter: write zero');
      if Written < 0 then
        raise EIOError.Create('TBufWriter: write failed');

      Inc(P, Written);
      Inc(Result, Written);
      Dec(Count, Written);
    end;
    Exit;
  end;

  // 2. 写入缓冲区
  while Count > 0 do
  begin
    Space := FCapacity - FPos;
    if Space = 0 then
    begin
      Flush;
      Space := FCapacity;
    end;

    ToCopy := Count;
    if ToCopy > Space then
      ToCopy := Space;

    Move(P^, FBuf[FPos], ToCopy);
    Inc(FPos, ToCopy);
    Inc(P, ToCopy);
    Inc(Result, ToCopy);
    Dec(Count, ToCopy);
  end;
end;

procedure TBufWriter.Flush;
var
  Written, Offset: SizeInt;
begin
  Offset := 0;
  while Offset < FPos do
  begin
    while True do
    begin
      try
        Written := FInner.Write(@FBuf[Offset], FPos - Offset);
        Break;
      except
        on E: EIOError do
        begin
          if E.Kind = ekInterrupted then
            Continue;
          raise;
        end;
      end;
    end;

    if Written = 0 then
      raise EIOError.Create(ekWriteZero, 'TBufWriter: flush write zero');
    if Written < 0 then
      raise EIOError.Create('TBufWriter: flush failed');

    Inc(Offset, Written);
  end;
  FPos := 0;
end;

function TBufWriter.Inner: IWriter;
begin
  Result := FInner;
end;

function TBufWriter.Buffered: SizeInt;
begin
  Result := FPos;
end;

function TBufWriter.Available: SizeInt;
begin
  Result := FCapacity - FPos;
end;

end.
