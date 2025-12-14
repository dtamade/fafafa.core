unit fafafa.core.io.combinators;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.combinators - 流组合子

  提供：
  - TIOCursor: 内存游标（可读写定位）
  - TLimitedReader: 限制读取字节数
  - TMultiReader: 串联多个读取器
  - TRepeatReader: 无限重复单字节
  - TEmptyReader: 空读取器（单例）
  - TDiscardWriter: 丢弃写入器（单例）

  参考: Rust std::io / Go io 包
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TIOCursor - 内存游标

    在 TBytes 上提供 IReader + IWriter + ISeeker 接口。
    适用于内存中的读写操作。

    用法：
      var C: TIOCursor;
      C := TIOCursor.FromBytes(SomeData);
      try
        N := C.Read(@Buf, 100);
        C.Seek(0, SeekStart);
      finally
        C.Free;
      end;
  }
  TIOCursor = class(TInterfacedObject, IReader, IWriter, ISeeker, IReadSeeker, 
                     IReadWriteSeeker, IReaderVectored, IWriterVectored)
  private
    FData: TBytes;
    FPos: SizeInt;
  public
    constructor Create; overload;
    constructor Create(ACapacity: SizeInt); overload;
    class function FromBytes(const AData: TBytes): TIOCursor; static;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { ISeeker }
    function Seek(Offset: Int64; Whence: Integer): Int64;

    { IReaderVectored }
    function ReadV(const IOV: TIOVecArray): SizeInt;

    { IWriterVectored }
    function WriteV(const IOV: TIOVecArray): SizeInt;

    { 额外方法 }
    function Position: SizeInt; inline;
    function Size: SizeInt; inline;
    function ToBytes: TBytes;
    procedure Reset;
  end;

  { TLimitedReader - 限制读取字节数

    包装一个 IReader，限制最多读取 N 字节。

    用法：
      LR := LimitReader(SomeReader, 1024);
  }
  TLimitedReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FRemaining: Int64;
  public
    constructor Create(AInner: IReader; ALimit: Int64);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { 额外方法 }
    function Remaining: Int64; inline;
  end;

  { TMultiReader - 串联多个读取器

    按顺序从多个 IReader 读取，前一个 EOF 后自动切换到下一个。

    用法：
      MR := MultiReader([Reader1, Reader2, Reader3]);
  }
  TMultiReader = class(TInterfacedObject, IReader)
  private
    FReaders: array of IReader;
    FIndex: Integer;
  public
    constructor Create(const AReaders: array of IReader);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TRepeatReader - 无限重复单字节

    返回无限的相同字节流。

    用法：
      RR := RepeatByte($00);  // 无限零字节
  }
  TRepeatReader = class(TInterfacedObject, IReader)
  private
    FByte: Byte;
  public
    constructor Create(AByte: Byte);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TEmptyReader - 空读取器

    立即返回 EOF (0)。
  }
  TEmptyReader = class(TInterfacedObject, IReader)
  public
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TDiscardWriter - 丢弃写入器

    丢弃所有写入的数据，总是返回成功。
  }
  TDiscardWriter = class(TInterfacedObject, IWriter)
  public
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

{ 工厂函数 }
function LimitReader(AInner: IReader; ALimit: Int64): IReader;
function MultiReader(const AReaders: array of IReader): IReader;
function RepeatByte(AByte: Byte): IReader;

{ 单例访问器 }
function EmptyReader: IReader;
function Discard: IWriter;

implementation

var
  GEmptyReader: IReader = nil;
  GDiscard: IWriter = nil;

{ TIOCursor }

constructor TIOCursor.Create;
begin
  inherited Create;
  SetLength(FData, 0);
  FPos := 0;
end;

constructor TIOCursor.Create(ACapacity: SizeInt);
begin
  inherited Create;
  if ACapacity < 0 then
    ACapacity := 0;
  SetLength(FData, ACapacity);
  FPos := 0;
end;

class function TIOCursor.FromBytes(const AData: TBytes): TIOCursor;
begin
  Result := TIOCursor.Create;
  Result.FData := Copy(AData);
  Result.FPos := 0;
end;

function TIOCursor.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Available: SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  Available := Length(FData) - FPos;
  if Available <= 0 then
    Exit;

  if Count > Available then
    Count := Available;

  Move(FData[FPos], Buf^, Count);
  Inc(FPos, Count);
  Result := Count;
end;

function TIOCursor.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  NewSize: SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 自动扩展
  NewSize := FPos + Count;
  if NewSize > Length(FData) then
    SetLength(FData, NewSize);

  Move(Buf^, FData[FPos], Count);
  Inc(FPos, Count);
  Result := Count;
end;

function TIOCursor.Seek(Offset: Int64; Whence: Integer): Int64;
var
  NewPos: Int64;
begin
  case Whence of
    SeekStart:   NewPos := Offset;
    SeekCurrent: NewPos := FPos + Offset;
    SeekEnd:     NewPos := Length(FData) + Offset;
  else
    raise EIOError.Create('TIOCursor.Seek: invalid whence');
  end;

  if NewPos < 0 then
    raise EIOError.Create('TIOCursor.Seek: negative position');

  {$IFDEF CPU32}
  // 32 位平台溢出检查
  if NewPos > High(SizeInt) then
    raise EIOError.Create('TIOCursor.Seek: position overflow');
  {$ENDIF}

  FPos := SizeInt(NewPos);
  Result := FPos;
end;

function TIOCursor.Position: SizeInt;
begin
  Result := FPos;
end;

function TIOCursor.Size: SizeInt;
begin
  Result := Length(FData);
end;

function TIOCursor.ToBytes: TBytes;
begin
  Result := Copy(FData, 0, Length(FData));
end;

procedure TIOCursor.Reset;
begin
  FPos := 0;
end;

function TIOCursor.ReadV(const IOV: TIOVecArray): SizeInt;
var
  I: Integer;
  Available, ToRead: SizeInt;
begin
  Result := 0;
  for I := 0 to High(IOV) do
  begin
    if (IOV[I].Base = nil) or (IOV[I].Len <= 0) then
      Continue;

    Available := Length(FData) - FPos;
    if Available <= 0 then
      Break;

    ToRead := IOV[I].Len;
    if ToRead > Available then
      ToRead := Available;

    Move(FData[FPos], IOV[I].Base^, ToRead);
    Inc(FPos, ToRead);
    Inc(Result, ToRead);

    // 如果该块未完全填充，说明已达到 EOF，停止
    if ToRead < IOV[I].Len then
      Break;
  end;
end;

function TIOCursor.WriteV(const IOV: TIOVecArray): SizeInt;
var
  I: Integer;
  TotalLen, NewSize: SizeInt;
begin
  Result := 0;

  // 计算总长度并一次性扩展
  TotalLen := 0;
  for I := 0 to High(IOV) do
    if IOV[I].Len > 0 then
      Inc(TotalLen, IOV[I].Len);

  if TotalLen = 0 then
    Exit;

  NewSize := FPos + TotalLen;
  if NewSize > Length(FData) then
    SetLength(FData, NewSize);

  // 依次写入
  for I := 0 to High(IOV) do
  begin
    if (IOV[I].Base = nil) or (IOV[I].Len <= 0) then
      Continue;

    Move(IOV[I].Base^, FData[FPos], IOV[I].Len);
    Inc(FPos, IOV[I].Len);
    Inc(Result, IOV[I].Len);
  end;
end;

{ TLimitedReader }

constructor TLimitedReader.Create(AInner: IReader; ALimit: Int64);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TLimitedReader: inner reader is nil');
  if ALimit < 0 then
    ALimit := 0;
  FInner := AInner;
  FRemaining := ALimit;
end;

function TLimitedReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) or (FRemaining <= 0) then
    Exit;

  if Count > FRemaining then
    Count := FRemaining;

  Result := FInner.Read(Buf, Count);
  if Result > 0 then
    Dec(FRemaining, Result);
end;

function TLimitedReader.Remaining: Int64;
begin
  Result := FRemaining;
end;

{ TMultiReader }

constructor TMultiReader.Create(const AReaders: array of IReader);
var
  I: Integer;
begin
  inherited Create;
  SetLength(FReaders, Length(AReaders));
  for I := 0 to High(AReaders) do
    FReaders[I] := AReaders[I];
  FIndex := 0;
end;

function TMultiReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  while FIndex < Length(FReaders) do
  begin
    if FReaders[FIndex] <> nil then
    begin
      Result := FReaders[FIndex].Read(Buf, Count);
      if Result > 0 then
        Exit;
    end;
    // EOF，切换到下一个
    Inc(FIndex);
  end;
  // 所有读取器都 EOF
  Result := 0;
end;

{ TRepeatReader }

constructor TRepeatReader.Create(AByte: Byte);
begin
  inherited Create;
  FByte := AByte;
end;

function TRepeatReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  FillChar(Buf^, Count, FByte);
  Result := Count;
end;

{ TEmptyReader }

function TEmptyReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;  // 立即 EOF
end;

{ TDiscardWriter }

function TDiscardWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if Count < 0 then
    Result := 0
  else
    Result := Count;  // 假装成功写入
end;

{ 工厂函数 }

function LimitReader(AInner: IReader; ALimit: Int64): IReader;
begin
  Result := TLimitedReader.Create(AInner, ALimit);
end;

function MultiReader(const AReaders: array of IReader): IReader;
begin
  Result := TMultiReader.Create(AReaders);
end;

function RepeatByte(AByte: Byte): IReader;
begin
  Result := TRepeatReader.Create(AByte);
end;

{ 单例访问器 }

function EmptyReader: IReader;
begin
  if GEmptyReader = nil then
    GEmptyReader := TEmptyReader.Create;
  Result := GEmptyReader;
end;

function Discard: IWriter;
begin
  if GDiscard = nil then
    GDiscard := TDiscardWriter.Create;
  Result := GDiscard;
end;

end.
