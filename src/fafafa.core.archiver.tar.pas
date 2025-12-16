unit fafafa.core.archiver.tar;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.archiver.interfaces;

type
  // POSIX ustar 头（简化版；后续补齐）
  TTarHeader = packed record
    Name: array[0..99] of AnsiChar;
    Mode: array[0..7] of AnsiChar;
    Uid: array[0..7] of AnsiChar;
    Gid: array[0..7] of AnsiChar;
    Size: array[0..11] of AnsiChar;
    MTime: array[0..11] of AnsiChar;
    Checksum: array[0..7] of AnsiChar;
    TypeFlag: AnsiChar;
    LinkName: array[0..99] of AnsiChar;
    Magic: array[0..5] of AnsiChar;   // 'ustar\0'
    Version: array[0..1] of AnsiChar; // '00'
    UName: array[0..31] of AnsiChar;
    GName: array[0..31] of AnsiChar;
    DevMajor: array[0..7] of AnsiChar;
    DevMinor: array[0..7] of AnsiChar;
    Prefix: array[0..155] of AnsiChar;
    Padding: array[0..11] of AnsiChar; // 对齐
  end;

  { TTarEntry }
  TTarEntry = class(TInterfacedObject, IArchiveEntry)
  private
    FName: string;
    FSize: Int64;
    FModifiedUtc: TDateTime;
    FIsDir: Boolean;
  protected
    function GetName: string;
    function GetSize: Int64;
    function GetModifiedUtc: TDateTime;
    function GetIsDirectory: Boolean;
  public
    property Name: string read GetName;
    property Size: Int64 read GetSize;
    property ModifiedUtc: TDateTime read GetModifiedUtc;
    property IsDirectory: Boolean read GetIsDirectory;
  end;

  { TTarWriter }
  TTarWriter = class(TInterfacedObject, IArchiveWriter)
  private
    FDest: TStream;
    FDeterministic: Boolean;
    FEnforcePathSafety: Boolean;
  public
    constructor Create(const Dest: TStream; const Deterministic: Boolean; const EnforcePathSafety: Boolean);
    procedure AddFile(const FilePath, ArchivePath: string);
    procedure AddDirectory(const ArchivePath: string);
    procedure AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
    procedure Finish;
  end;

  { TTarReader }
  TTarReader = class(TInterfacedObject, IArchiveReader)
  private
    FSource: TStream;
    FStartPos: Int64;
    FRemain: Int64;
    FPad: Int64;
    FEOF: Boolean;
    FCurrent: TTarEntry;
    FOwnsSource: Boolean;
    // PAX pending overrides
    FHavePaxPath: Boolean;
    FPaxPath: string;
    FHavePaxMTime: Boolean;
    FPaxMTime: Int64;
  public
    FEnforcePathSafety: Boolean;

    constructor Create(const Source: TStream; const OwnsSource: Boolean; const EnforcePathSafety: Boolean);
    destructor Destroy; override;
    function Next(out Entry: IArchiveEntry): Boolean;
    procedure ExtractCurrentToStream(const Dest: TStream);
    procedure SkipCurrent;
    procedure Reset;
  end;

implementation

uses
  fafafa.core.math;

{ TTarEntry }

function TTarEntry.GetName: string; begin Result := FName; end;
function TTarEntry.GetSize: Int64; begin Result := FSize; end;
function TTarEntry.GetModifiedUtc: TDateTime; begin Result := FModifiedUtc; end;
function TTarEntry.GetIsDirectory: Boolean; begin Result := FIsDir; end;

{ TTarWriter }

function DateTimeToUnixSeconds(const DT: TDateTime): Int64;
begin
  Result := Round((DT - 25569) * 86400.0);
end;

procedure ZeroFill(var H: TTarHeader);
begin
  FillChar(H, SizeOf(H), 0);
end;

procedure PutString(var Dest; MaxLen: SizeInt; const S: AnsiString);
var P: PAnsiChar; n, i: SizeInt;
begin
  P := @Dest; n := Length(S); if n > MaxLen then n := MaxLen;
  for i := 0 to n-1 do P[i] := S[i+1];
  if n <= MaxLen then P[n] := #0;
end;

procedure PutOctal(var Field; Width: SizeInt; const Value: Int64);
var buf: array[0..31] of AnsiChar; i: Integer; v: UInt64; P: PAnsiChar;
begin
  v := UInt64(Value);
  i := High(buf);
  buf[i] := #0; Dec(i);
  buf[i] := ' '; Dec(i);
  repeat
    buf[i] := AnsiChar(Ord('0') + (v and 7));
    v := v shr 3; Dec(i);
  until (v = 0) or (i < 0);
  while (High(buf)-i < Width) and (i >= 0) do begin buf[i] := '0'; Dec(i); end;
  Inc(i);
  P := @Field;
  Move(buf[i], P^, Width);
end;

procedure FinalizeChecksum(var H: TTarHeader);
var sum: Cardinal; i: Integer; p: PByte;
begin
  // checksum 字段先填空格
  FillChar(H.Checksum, SizeOf(H.Checksum), Ord(' '));
  sum := 0; p := @H;
  for i := 0 to SizeOf(H)-1 do Inc(sum, p[i]);
  PutOctal(H.Checksum, 8, sum);
end;

procedure WritePaxRecord(const Dest: TStream; const Key, Value: AnsiString);
var line: AnsiString; len, digits: Integer;
begin
  // format: <len> <key>=<value>\n ; len 包含自身数字个数
  line := ' ' + Key + '=' + Value + #10; // 先占位一个空格，随后替换为数字
  // 先估算一次长度（包含数字位数）并迭代直到稳定
  len := Length(line) + 1; // +1 for at least one digit
  repeat
    digits := Length(IntToStr(len));
    len := Length(line) + digits;
  until digits = Length(IntToStr(len));
  // 写入长度数字
  Dest.WriteBuffer(PAnsiChar(AnsiString(IntToStr(len)))^, digits);
  // 写入余下的内容（空格 + key=value + LF）
  if Length(line) > 0 then Dest.WriteBuffer(line[1], Length(line));
end;

procedure WritePaxExtendedHeader(const Dest: TStream; const Path: string; const MTime: Int64; IncludeMTime: Boolean);
var H: TTarHeader; payload: TMemoryStream; paxPath: AnsiString; pad: Int64; zeros: array[0..511] of byte; chunk: SizeInt;
begin
  payload := TMemoryStream.Create;
  try
    paxPath := AnsiString(UTF8Encode(Path));
    WritePaxRecord(payload, 'path', paxPath);
    if IncludeMTime then WritePaxRecord(payload, 'mtime', AnsiString(IntToStr(MTime)));

    ZeroFill(H);
    // 使用固定名称，避免依赖 SplitPathForUstar 次序
    PutString(H.Name, SizeOf(H.Name)-1, AnsiString('PaxHeaders.0'));
    PutString(H.Prefix, SizeOf(H.Prefix)-1, AnsiString('./'));
    PutString(H.Magic, 6, 'ustar'); H.Magic[5] := #0;
    PutString(H.Version, 2, '00');
    H.TypeFlag := 'x';
    PutOctal(H.Mode, 8, 420);
    PutOctal(H.Uid, 8, 0);
    PutOctal(H.Gid, 8, 0);
    PutOctal(H.Size, 12, payload.Size);
    PutOctal(H.MTime, 12, 0);
    FinalizeChecksum(H);
    Dest.WriteBuffer(H, SizeOf(H));

    if payload.Size > 0 then begin
      payload.Position := 0;
      Dest.CopyFrom(payload, payload.Size);
      pad := (512 - (payload.Size mod 512)) mod 512;
      if pad > 0 then begin
        FillChar(zeros, SizeOf(zeros), 0);
        while pad > 0 do begin
          if pad > SizeOf(zeros) then chunk := SizeOf(zeros) else chunk := pad;
          Dest.WriteBuffer(zeros, chunk);
          Dec(pad, chunk);
        end;
      end;
    end;
  finally
    payload.Free;
  end;
end;

procedure SplitPathForUstar(const FullName: string; out Prefix, Name: AnsiString);
var slashPos: SizeInt; tmp: string;
begin
  tmp := StringReplace(FullName, '\', '/', [rfReplaceAll]);
  // 直接放入 name 若<=100（PAX 上层会决定是否写扩展）
  if Length(tmp) <= 100 then begin Prefix := ''; Name := AnsiString(tmp); Exit; end;
  // 尝试使用 prefix + name
  slashPos := Length(tmp);
  while (slashPos > 0) and (tmp[slashPos] <> '/') do Dec(slashPos);
  if (slashPos > 0) and (slashPos-1 <= 155) and (Length(tmp) - slashPos <= 100) then begin
    Prefix := AnsiString(Copy(tmp, 1, slashPos-1));
    Name := AnsiString(Copy(tmp, slashPos+1, MaxInt));
  end else begin
    // 简化：截断（后续用 PAX 扩展解决）
    Prefix := '';
    Name := AnsiString(Copy(tmp, 1, 100));
  end;
end;

procedure WriteHeader(const Dest: TStream; const APath: string; ASize: Int64; AMTime: Int64; AIsDir: Boolean; Deterministic: Boolean);
var H: TTarHeader; prefix,name: AnsiString; mode: Int64;
begin
  ZeroFill(H);
  SplitPathForUstar(APath, prefix, name);
  PutString(H.Name, SizeOf(H.Name)-1, name);
  PutString(H.Prefix, SizeOf(H.Prefix)-1, prefix);
  // magic/version
  PutString(H.Magic, 6, 'ustar'); H.Magic[5] := #0;
  PutString(H.Version, 2, '00');
  // typeflag
  if AIsDir then H.TypeFlag := '5' else H.TypeFlag := '0';
  // mode/uid/gid
  if AIsDir then mode := 493 else mode := 420; // 0755/0644
  PutOctal(H.Mode, 8, mode);
  PutOctal(H.Uid, 8, 0);
  PutOctal(H.Gid, 8, 0);
  // size/mtime
  PutOctal(H.Size, 12, ASize);
  if Deterministic then AMTime := 0;
  PutOctal(H.MTime, 12, AMTime);
  // uname/gname 空即可
  FinalizeChecksum(H);
  Dest.WriteBuffer(H, SizeOf(H));
end;

procedure WriteZeros(const Dest: TStream; Count: Int64);
var buf: array[0..511] of byte; n: Int64;
begin
  FillChar(buf, SizeOf(buf), 0);
  while Count > 0 do begin
    if Count >= SizeOf(buf) then n := SizeOf(buf) else n := Count;
    Dest.WriteBuffer(buf, n);
    Dec(Count, n);
  end;
end;

constructor TTarWriter.Create(const Dest: TStream; const Deterministic: Boolean; const EnforcePathSafety: Boolean);
begin
  inherited Create;
  FDest := Dest;
  FDeterministic := Deterministic;
  FEnforcePathSafety := EnforcePathSafety;
end;

procedure TTarWriter.AddFile(const FilePath, ArchivePath: string);
var fs: TFileStream; mtime: Int64; size: Int64; dt: TDateTime;
begin
  fs := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    size := fs.Size;
    {$IFDEF MSWINDOWS}
    dt := FileDateToDateTime(FileAge(FilePath));
    {$ELSE}
    dt := FileDateToDateTime(FileAge(FilePath));
    {$ENDIF}
    mtime := DateTimeToUnixSeconds(dt);
    AddStream(ArchivePath, fs, dt);
  finally
    fs.Free;
  end;
end;

procedure TTarWriter.AddDirectory(const ArchivePath: string);
var name, norm: string; mtime: Int64;
begin
  name := ArchivePath;
  // 路径安全检查（与 AddStream 对称）：禁止绝对路径与 '/../'
  if FEnforcePathSafety and (name <> '') then begin
    norm := StringReplace(name, '\\', '/', [rfReplaceAll]);
    if (norm[1] = '/') or (Pos('/../', '/' + norm + '/') > 0) then
      raise EArchiverError.Create('tar: unsafe path to write');
  end;
  if (name = '') or (name[Length(name)] <> '/') then name := name + '/';
  mtime := 0;
  WriteHeader(FDest, name, 0, mtime, True, FDeterministic);
  // 目录无 payload，无需对齐
end;


procedure TTarWriter.AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
var name, norm: string; mtime: Int64; size: Int64; buf: array[0..8191] of byte; n: SizeInt; remain, pad: Int64;
begin
  name := ArchivePath;
  if (name <> '') and (name[Length(name)] = '/') then
    raise EArchiverError.Create('tar: AddStream name must not end with /');
  // 路径安全（与 Reader 对称）：禁止绝对路径与 '/../'
  if FEnforcePathSafety and (name <> '') then begin
    norm := StringReplace(name, '\\', '/', [rfReplaceAll]);
    if (norm[1] = '/') or (Pos('/../', '/' + norm + '/') > 0) then
      raise EArchiverError.Create('tar: unsafe path to write');
  end;
  size := Source.Size - Source.Position;
  mtime := DateTimeToUnixSeconds(ModifiedUtc);
  // 若 name 超过 ustar 限制，先写 PAX 扩展头
  if Length(StringReplace(name, '\\', '/', [rfReplaceAll])) > 100 then
    WritePaxExtendedHeader(FDest, name, mtime, not FDeterministic);
  WriteHeader(FDest, name, size, mtime, False, FDeterministic);
  // copy payload
  remain := size;
  while remain > 0 do begin
    if remain > SizeOf(buf) then n := SizeOf(buf) else n := remain;
    n := Source.Read(buf, n);
    if n <= 0 then raise EArchiverError.Create('tar: unexpected EOF while writing');
    FDest.WriteBuffer(buf, n);
    Dec(remain, n);
  end;
  // padding to 512
  pad := (512 - (size mod 512)) mod 512;
  if pad > 0 then WriteZeros(FDest, pad);
end;

procedure TTarWriter.Finish;
begin
  // 写入两个 512 字节全零块
  WriteZeros(FDest, 1024);
  // 底层压缩流的释放交给门面适配器处理（避免双重释放）

end;

procedure ParsePaxPayload(const Src: TStream; Count: Int64; out OutPath: string; out HavePath: Boolean; out OutMTime: Int64; out HaveMTime: Boolean);
var buf: array[0..8191] of byte; tmp: RawByteString; n: SizeInt; s: RawByteString; i, sp: SizeInt; line: RawByteString; L: Integer; key, val: string;
begin
  HavePath := False; HaveMTime := False; OutPath := ''; OutMTime := 0;
  while Count > 0 do begin
    if Count > SizeOf(buf) then n := SizeOf(buf) else n := Count;
    n := Src.Read(buf, n);
    if n <= 0 then raise EArchiverError.Create('tar: short read pax payload');
    Dec(Count, n);
    SetString(s, PAnsiChar(@buf[0]), n);
    tmp := tmp + s;
    // parse lines
    i := 1;
    while i <= Length(tmp) do begin
      // line format: <len> <key>=<value>\n
      sp := i;
      while (sp <= Length(tmp)) and (tmp[sp] <> ' ') do Inc(sp);
      if sp > Length(tmp) then break; // incomplete length
      L := StrToIntDef(Copy(string(tmp), i, sp - i), -1);
      if L <= 0 then raise EArchiverError.Create('tar: invalid pax length');
      if i + L - 1 > Length(tmp) then break; // incomplete line
      line := Copy(tmp, i, L);
      i := i + L;
      // parse key=value\n
      // remove length and space prefix
      delete(line, 1, (Pos(' ', string(line))));
      // strip trailing newline
      if (Length(line) > 0) and (line[Length(line)] = #10) then SetLength(line, Length(line)-1);
      // split at first '='
      sp := Pos('=', string(line));
      if sp > 0 then begin
        key := Copy(string(line), 1, sp-1);
        val := Copy(string(line), sp+1, MaxInt);
        if key = 'path' then begin OutPath := UTF8Decode(AnsiString(val)); HavePath := True; end
        else if key = 'mtime' then begin HaveMTime := TryStrToInt64(val, OutMTime); end;
      end;
    end;
    // remove consumed
    if i > 1 then tmp := Copy(tmp, i, MaxInt);
  end;
end;

{ TTarReader }

constructor TTarReader.Create(const Source: TStream; const OwnsSource: Boolean; const EnforcePathSafety: Boolean);
begin
  inherited Create;
  FSource := Source;
  try
    FStartPos := Source.Position;
  except
    // 非可寻址流（例如 gzip 解码流）：无法重置，记录为 0
    FStartPos := 0;
  end;
  FRemain := 0;
  FPad := 0;
  FEOF := False;
  FCurrent := nil;
  FOwnsSource := OwnsSource;
  FEnforcePathSafety := EnforcePathSafety;
end;

function IsAllZero(const Buf; Count: SizeInt): Boolean;
var P: PByte; I: SizeInt;
begin
  P := @Buf; for I := 0 to Count-1 do if P[I] <> 0 then exit(False); Result := True;
end;

function ComputeHeaderChecksum(const H: TTarHeader): Cardinal;
var sum: Cardinal; i: Integer; p: PByte; tmp: TTarHeader;
begin
  // treat checksum field as spaces when computing
  tmp := H;
  FillChar(tmp.Checksum, SizeOf(tmp.Checksum), Ord(' '));
  sum := 0; p := @tmp;
  for i := 0 to SizeOf(tmp)-1 do Inc(sum, p[i]);
  Result := sum;
end;


function OctalToInt64(const A: array of AnsiChar): Int64;
var i: Integer; v: Int64;
begin
  v := 0;
  for i := 0 to High(A) do begin
    if (A[i] < '0') or (A[i] > '7') then break;
    v := (v shl 3) + Ord(A[i]) - Ord('0');
  end;
  Result := v;
end;

function TrimZ(const A: array of AnsiChar): string;
var i,n: Integer;
begin
  n := Length(A); i := 0;
  while (i < n) and (A[i] <> #0) do Inc(i);
  SetString(Result, PChar(@A[0]), i);
end;

procedure ConsumeBytes(const S: TStream; Count: Int64);
var
  buf: array[0..8191] of byte;
  n: Integer;
begin
  while Count > 0 do
  begin
    if Count > SizeOf(buf) then n := SizeOf(buf) else n := Count;
    n := S.Read(buf, n);
    if n <= 0 then raise EArchiverError.Create('tar: short read while skipping');
    Dec(Count, n);
  end;
end;

// 无分配的路径安全检查：直接在头部 Name 或字符串上扫描
function IsUnsafeHeaderName(const A: array of AnsiChar): Boolean;
var i: Integer; c, next1, next2: AnsiChar; seenFirst: Boolean;
begin
  Result := False; seenFirst := False;
  for i := 0 to High(A) do begin
    c := A[i];
    if c = #0 then Break;
    if c = '\\' then c := '/';
    if not seenFirst then begin
      // 绝对路径（以 '/' 开头）或以 ".." 开头（并紧跟分隔符）
      if (c = '/') then Exit(True);
      if (c = '.') and (i+1 <= High(A)) then begin
        next1 := A[i+1]; if next1 = '\\' then next1 := '/';
        if (next1 = '.') then begin
          if (i+2 <= High(A)) then begin
            next2 := A[i+2]; if next2 = '\\' then next2 := '/';
            if (next2 = '/') then Exit(True);
          end else begin
            // 名称仅为 ".." 也视为不安全
            Exit(True);
          end;
        end;
      end;
      seenFirst := True;
    end;
    // 检测内部 '/../'
    if (c = '.') and (i > 0) and (i+1 <= High(A)) then begin
      next1 := A[i-1]; if next1 = '\\' then next1 := '/';
      next2 := A[i+1]; if next2 = '\\' then next2 := '/';
      if (next1 = '/') and (next2 = '.') then begin
        if (i+2 <= High(A)) then begin
          c := A[i+2]; if c = '\\' then c := '/';
          if c = '/' then Exit(True);
        end;
      end;
    end;
  end;
end;

function IsUnsafePathStr(const S: string): Boolean;
var i, n: Integer; c, p1, p2: Char;
begin
  Result := False; n := Length(S); if n = 0 then Exit(False);
  // 首字符绝对路径
  c := S[1]; if (c = '/') or (c = '\\') then Exit(True);
  p1 := #0; p2 := #0;
  for i := 1 to n do begin
    c := S[i]; if c = '\\' then c := '/';
    if (p2 = '/') and (p1 = '.') and (c = '.') then begin
      if (i < n) and ((S[i+1] = '/') or (S[i+1] = '\\')) then Exit(True);
    end;
    p2 := p1; p1 := c;
  end;
end;

function TTarReader.Next(out Entry: IArchiveEntry): Boolean;
var H: TTarHeader; r: SizeInt; name: string; size: Int64; mtime: Int64; isdir: Boolean; norm: string; expected: Cardinal; gotVal: Int64;
begin
  Entry := nil;
  // 跳过上一个条目的剩余与对齐（流式）
  if FRemain > 0 then ConsumeBytes(FSource, FRemain + FPad);
  FRemain := 0; FPad := 0; FCurrent := nil;

  r := FSource.Read(H, SizeOf(H));
  if r = 0 then exit(False);
  if r <> SizeOf(H) then raise EArchiverError.Create('tar: short read');
  // 处理 PAX 扩展头（typeflag='x'）
  if H.TypeFlag = 'x' then begin
    size := OctalToInt64(H.Size);
    ParsePaxPayload(FSource, size, FPaxPath, FHavePaxPath, FPaxMTime, FHavePaxMTime);
    // 跳过对齐（流式）
    FPad := (512 - (size mod 512)) mod 512;
    if FPad > 0 then ConsumeBytes(FSource, FPad);
    // 读取下一头部
    r := FSource.Read(H, SizeOf(H));
    if r <> SizeOf(H) then raise EArchiverError.Create('tar: short read after pax');
  end;
  if IsAllZero(H, SizeOf(H)) then begin
    // 读到第一个全零块；再读一块确认
    r := FSource.Read(H, SizeOf(H));
    if (r = SizeOf(H)) and IsAllZero(H, SizeOf(H)) then begin FEOF := True; exit(False); end
    else begin
      if (r < SizeOf(H)) then begin FEOF := True; exit(False); end
      else raise EArchiverError.Create('tar: malformed EOF');
    end;
  end;

  // 校验 header checksum
  expected := ComputeHeaderChecksum(H);
  // 宽松解析八进制（忽略尾部空格/零）；不支持 base-256 此处暂略
  gotVal := OctalToInt64(H.Checksum);
  if UInt64(gotVal) <> UInt64(expected) then
    raise EArchiverError.Create('tar: invalid header checksum');

  size := OctalToInt64(H.Size);
  mtime := OctalToInt64(H.MTime);

  // 先做路径安全校验（零分配版本）：直接检查头部 Name 字段，避免提前分配字符串
  if (FEnforcePathSafety) then begin
    if IsUnsafeHeaderName(H.Name) then
      raise EArchiverError.Create('tar: unsafe path detected');
  end;

  // 生成名称并应用 PAX 覆盖
  name := TrimZ(H.Name);
  if FHavePaxPath then begin name := FPaxPath; FHavePaxPath := False; end;
  if FHavePaxMTime then begin { mtime := FPaxMTime; } FHavePaxMTime := False; end;

  // 应用路径：PAX 覆盖后也做一次字符串版检查（包括以 ".." 开头的情况）
  if (FEnforcePathSafety) and (name <> '') then begin
    if (IsUnsafePathStr(name)) or (Copy(name,1,2) = '..') then
      raise EArchiverError.Create('tar: unsafe path detected');
  end;

  // 计算目录标志
  isdir := (H.TypeFlag = '5') or ((size = 0) and (name <> '') and (name[Length(name)] = '/'));

  // 校验通过后再创建条目对象
  FCurrent := TTarEntry.Create;
  FCurrent.FName := name;
  FCurrent.FSize := size;
  FCurrent.FModifiedUtc := 25569 + (mtime / 86400.0); // Unix epoch -> Delphi TDateTime
  FCurrent.FIsDir := isdir;

  FRemain := size;
  FPad := (512 - (size mod 512)) mod 512;
  Entry := FCurrent;
  Result := True;
end;

procedure TTarReader.ExtractCurrentToStream(const Dest: TStream);
var buf: array[0..8191] of byte; toRead, n: SizeInt;
begin
  if (FCurrent = nil) then raise EArchiverError.Create('tar: no current entry');
  if FCurrent.FIsDir then exit; // 目录无内容
  toRead := 0;
  while FRemain > 0 do begin
    if FRemain > SizeOf(buf) then toRead := SizeOf(buf) else toRead := FRemain;
    n := FSource.Read(buf, toRead);
    if (n <= 0) or (n <> toRead) then raise EArchiverError.Create('tar: short read payload');
    Dest.WriteBuffer(buf, n);
    Dec(FRemain, n);
  end;
  if FRemain <> 0 then raise EArchiverError.Create('tar: short read payload');
  // 跳过对齐填充（流式）
  if FPad > 0 then ConsumeBytes(FSource, FPad);
  FPad := 0;
end;

procedure TTarReader.SkipCurrent;
begin
  if FRemain > 0 then ConsumeBytes(FSource, FRemain + FPad);
  FRemain := 0; FPad := 0; FCurrent := nil;
end;

destructor TTarReader.Destroy;
begin
  // 注意：当前条目对象可能已通过接口返回给调用方，不应在此处释放，交由接口引用计数管理
  FCurrent := nil;
  if FOwnsSource then FSource.Free;
  inherited Destroy;
end;

procedure TTarReader.Reset;
begin
  try
    FSource.Position := FStartPos;
  except
    // 非可寻址流：忽略 Reset（保持当前位置）
  end;
  FRemain := 0; FPad := 0; FEOF := False; FCurrent := nil;
end;

end.

