unit fafafa.core.io.mmap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.mmap - 内存映射文件读取器

  提供：
  - TMmapReader: 使用 mmap 的只读文件映射（Unix）

  在不支持 mmap 或映射失败时，优雅降级为普通文件读取。

  参考: Rust memmap2, Go mmap-go
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

type
  { TMmapReader - 内存映射只读文件读取器

    使用操作系统的内存映射机制提供高效的文件只读访问。
    实现 IReader + ISeeker + ICloser。

    限制：
    - 仅支持只读访问
    - 文件大小受限于可用虚拟地址空间
    - Unix 平台使用 mmap，Windows 暂不支持（回退到普通文件读取）

    用法：
      R := MmapRead('/path/to/file');
      try
        // 像普通 IReadSeeker 一样使用
        N := R.Read(@Buf, Size);
        R.Seek(0, SeekStart);
      finally
        R.Close;
      end;
  }
  TMmapReader = class(TInterfacedObject, IReader, ISeeker, ICloser, IReadSeeker, IReadCloser)
  private
    FPath: string;
    FData: PByte;
    FSize: SizeInt;
    FPos: SizeInt;
    {$IFDEF UNIX}
    FFd: Integer;
    {$ENDIF}
    FClosed: Boolean;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { ISeeker }
    function Seek(Offset: Int64; Whence: Integer): Int64;

    { ICloser }
    procedure Close;

    { 属性 }
    property Size: SizeInt read FSize;
    property Path: string read FPath;
  end;

{ 工厂函数 }

{ MmapRead - 创建内存映射文件读取器

  Unix: 使用 mmap 映射文件
  Windows/失败: 抛出 EIOError

  如需自动回退，请使用 IO.MmapRead 门面方法。
}
function MmapRead(const APath: string): TMmapReader;

{ MmapSupported - 检查当前平台是否支持 mmap }
function MmapSupported: Boolean;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.io.error;

{$IFDEF UNIX}
const
  PROT_READ = 1;
  MAP_PRIVATE = 2;
  MAP_FAILED = Pointer(-1);
{$ENDIF}

{ TMmapReader }

constructor TMmapReader.Create(const APath: string);
{$IFDEF UNIX}
var
  StatBuf: TStat;
  MappedPtr: Pointer;
{$ENDIF}
begin
  inherited Create;
  FPath := APath;
  FData := nil;
  FSize := 0;
  FPos := 0;
  FClosed := False;
  {$IFDEF UNIX}
  FFd := -1;
  {$ENDIF}

  {$IFDEF UNIX}
  // 打开文件
  FFd := FpOpen(PChar(APath), O_RDONLY);
  if FFd < 0 then
    raise IOErrorWrap(ekNotFound, 'mmap_open', APath,
      EIOError.Create(ekNotFound, 'mmap_open', APath, fpgeterrno, 'open failed'));

  // 获取文件大小
  if FpFstat(FFd, StatBuf) < 0 then
  begin
    FpClose(FFd);
    FFd := -1;
    raise IOErrorWrap(ekUnknown, 'mmap_stat', APath,
      EIOError.Create(ekUnknown, 'mmap_stat', APath, fpgeterrno, 'fstat failed'));
  end;

  FSize := StatBuf.st_size;

  // 空文件特殊处理
  if FSize = 0 then
  begin
    FData := nil;
    Exit;
  end;

  // mmap 映射
  MappedPtr := Fpmmap(nil, FSize, PROT_READ, MAP_PRIVATE, FFd, 0);
  if MappedPtr = MAP_FAILED then
  begin
    FpClose(FFd);
    FFd := -1;
    raise IOErrorWrap(ekUnknown, 'mmap', APath,
      EIOError.Create(ekUnknown, 'mmap', APath, fpgeterrno, 'mmap failed'));
  end;

  FData := PByte(MappedPtr);
  {$ELSE}
  // 非 Unix 平台不支持
  raise EIOError.Create(ekUnknown, 'mmap', APath, 0, 'mmap not supported on this platform');
  {$ENDIF}
end;

destructor TMmapReader.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TMmapReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Available: SizeInt;
begin
  Result := 0;
  if FClosed or (Buf = nil) or (Count <= 0) then
    Exit;

  Available := FSize - FPos;
  if Available <= 0 then
    Exit;

  if Count > Available then
    Count := Available;

  Move(FData[FPos], Buf^, Count);
  Inc(FPos, Count);
  Result := Count;
end;

function TMmapReader.Seek(Offset: Int64; Whence: Integer): Int64;
var
  NewPos: Int64;
begin
  if FClosed then
    raise EIOError.Create(ekBrokenPipe, 'seek on closed mmap reader');

  case Whence of
    SeekStart:   NewPos := Offset;
    SeekCurrent: NewPos := FPos + Offset;
    SeekEnd:     NewPos := FSize + Offset;
  else
    raise EIOError.Create(ekInvalidInput, 'invalid whence');
  end;

  if NewPos < 0 then
    raise EIOError.Create(ekInvalidInput, 'negative seek position');

  FPos := SizeInt(NewPos);
  Result := FPos;
end;

procedure TMmapReader.Close;
begin
  if FClosed then
    Exit;

  {$IFDEF UNIX}
  if (FData <> nil) and (FSize > 0) then
    Fpmunmap(FData, FSize);

  if FFd >= 0 then
    FpClose(FFd);

  FFd := -1;
  {$ENDIF}

  FData := nil;
  FSize := 0;
  FPos := 0;
  FClosed := True;
end;

{ 工厂函数 }

function MmapRead(const APath: string): TMmapReader;
begin
  Result := TMmapReader.Create(APath);
end;

function MmapSupported: Boolean;
begin
  {$IFDEF UNIX}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

end.
