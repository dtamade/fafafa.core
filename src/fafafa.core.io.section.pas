unit fafafa.core.io.section;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.section - 区段读取器

  提供：
  - TSectionReader: 只读取 IReadSeeker 的指定区段

  适用于读取大文件的某一部分、处理嵌入式数据等场景。

  参考: Go io.SectionReader
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TSectionReader - 区段读取器

    从 IReadSeeker 的指定偏移量开始，读取最多 N 字节。
    支持在区段内进行 Seek 操作。

    用法：
      SR := TSectionReader.Create(Inner, 100, 50);  // 从偏移100读取50字节
      try
        SR.Read(@Buf, 50);
      finally
        SR.Free;
      end;
  }
  TSectionReader = class(TInterfacedObject, IReader, ISeeker, IReadSeeker)
  private
    FInner: IReadSeeker;
    FBase: Int64;      // 区段在底层流中的起始位置
    FSize: Int64;      // 区段大小
    FOffset: Int64;    // 当前在区段内的偏移量
  public
    constructor Create(AInner: IReadSeeker; AOffset, ASize: Int64);

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { ISeeker }
    function Seek(Offset: Int64; Whence: Integer): Int64;

    { 额外方法 }
    function Size: Int64; inline;
    function Remaining: Int64; inline;
  end;

{ 工厂函数 }
function SectionReader(AInner: IReadSeeker; AOffset, ASize: Int64): IReader;

implementation

{ TSectionReader }

constructor TSectionReader.Create(AInner: IReadSeeker; AOffset, ASize: Int64);
begin
  inherited Create;
  if AInner = nil then
    raise EIOError.Create('TSectionReader: inner reader is nil');
  if AOffset < 0 then
    AOffset := 0;
  if ASize < 0 then
    ASize := 0;

  FInner := AInner;
  FBase := AOffset;
  FSize := ASize;
  FOffset := 0;
end;

function TSectionReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  MaxRead: Int64;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  // 计算可读取的最大字节数
  MaxRead := FSize - FOffset;
  if MaxRead <= 0 then
    Exit;  // 已到区段末尾

  if Count > MaxRead then
    Count := MaxRead;

  // Seek 到底层流的正确位置
  FInner.Seek(FBase + FOffset, SeekStart);

  // 读取数据
  Result := FInner.Read(Buf, Count);
  if Result > 0 then
    Inc(FOffset, Result);
end;

function TSectionReader.Seek(Offset: Int64; Whence: Integer): Int64;
var
  NewOffset: Int64;
begin
  case Whence of
    SeekStart:   NewOffset := Offset;
    SeekCurrent: NewOffset := FOffset + Offset;
    SeekEnd:     NewOffset := FSize + Offset;
  else
    raise EIOError.Create(ekInvalidInput, 'TSectionReader.Seek: invalid whence');
  end;

  // 检查负数偏移 (SeekStart before 0)
  if NewOffset < 0 then
    raise EIOError.Create(ekInvalidInput, 'SectionReader.Seek: negative position');
  
  // 不限制超过 FSize，允许 seek 到末尾之后 (Read 将返回 EOF)
  
  FOffset := NewOffset;
  Result := FOffset;
end;

function TSectionReader.Size: Int64;
begin
  Result := FSize;
end;

function TSectionReader.Remaining: Int64;
begin
  Result := FSize - FOffset;
end;

{ 工厂函数 }

function SectionReader(AInner: IReadSeeker; AOffset, ASize: Int64): IReader;
begin
  Result := TSectionReader.Create(AInner, AOffset, ASize);
end;

end.
