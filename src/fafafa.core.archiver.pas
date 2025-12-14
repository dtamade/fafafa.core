unit fafafa.core.archiver;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.archiver.interfaces;

type
  TArchiveOptions = record
    Format: TArchiveFormat;              // afTar/afZip
    Compression: TCompressionAlgorithm;  // caNone/caGZip/...
    CompressionLevel: Integer;           // 0=no compression; 1..9 typical range
    Deterministic: Boolean;              // 可重复构建（统一 mtime/uid/gid/排序）
    EnforcePathSafety: Boolean;          // 路径穿越防护（Reader/Writer 可使用），默认建议 True
    StoreUnixPermissions: Boolean;
    StoreTimestampsUtc: Boolean;
    FollowSymlinks: Boolean;
  end;

function DefaultArchiveOptions: TArchiveOptions;


// Compression Provider Registry（简化占位；后续移至独立单元）
procedure RegisterCompressionProvider(const Provider: ICompressionProvider; const Priority: Integer = 0);
function ResolveCompressionProvider(const Algorithm: TCompressionAlgorithm): ICompressionProvider;
procedure SetDefaultCompressionProvider(const Algorithm: TCompressionAlgorithm; const Provider: ICompressionProvider);
procedure ArchiverShutdown; // 主动释放注册表等全局资源

function CreateArchiveWriter(const Dest: TStream; const Options: TArchiveOptions): IArchiveWriter;
function CreateArchiveReader(const Source: TStream; const Format: TArchiveFormat): IArchiveReader; overload;
function CreateArchiveReader(const Source: TStream; const Format: TArchiveFormat; const Compression: TCompressionAlgorithm): IArchiveReader; overload;
function CreateArchiveReader(const Source: TStream; const Options: TArchiveOptions): IArchiveReader; overload;


implementation

uses
  // 未来按需引入 zip/tar 后端实现单元
  // fafafa.core.archiver.zip
  fafafa.core.archiver.tar,
  fafafa.core.archiver.codec.deflate.paszlib,
  fafafa.core.archiver.codec.gzip,
  Generics.Collections;

type
  // 适配器：在 Finish 后释放外层压缩流，确保尾部/trailer 被正确写入
  TWriterWithOuterStream = class(TInterfacedObject, IArchiveWriter)
  private
    FInner: IArchiveWriter;
    FOuter: TStream;
  public
    constructor Create(const Inner: IArchiveWriter; const Outer: TStream);
    destructor Destroy; override;
    procedure AddFile(const FilePath: string; const ArchivePath: string);
    procedure AddDirectory(const ArchivePath: string);
    procedure AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
    procedure Finish;
  end;
{ TWriterWithOuterStream }
constructor TWriterWithOuterStream.Create(const Inner: IArchiveWriter; const Outer: TStream);
begin
  inherited Create;
  FInner := Inner;
  FOuter := Outer;
end;

destructor TWriterWithOuterStream.Destroy;
begin
  // 若调用方忘记 Finish，也尽力释放压缩流避免泄漏；
  // 但不主动调用 FInner.Finish（避免重复 trailer）。
  if FOuter <> nil then FOuter.Free;
  inherited Destroy;
end;

procedure TWriterWithOuterStream.AddFile(const FilePath: string; const ArchivePath: string);
begin
  FInner.AddFile(FilePath, ArchivePath);
end;

procedure TWriterWithOuterStream.AddDirectory(const ArchivePath: string);
begin
  FInner.AddDirectory(ArchivePath);
end;

procedure TWriterWithOuterStream.AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
begin
  FInner.AddStream(ArchivePath, Source, ModifiedUtc);
end;

procedure TWriterWithOuterStream.Finish;
begin
  FInner.Finish;
  if FOuter <> nil then begin
    FOuter.Free;
    FOuter := nil;
  end;
end;


var
  gProviders: specialize TDictionary<TCompressionAlgorithm, ICompressionProvider>;
  gDefaults:  specialize TDictionary<TCompressionAlgorithm, ICompressionProvider>;

procedure EnsureRegistry;
begin
  if gProviders = nil then gProviders := specialize TDictionary<TCompressionAlgorithm, ICompressionProvider>.Create;
  if gDefaults  = nil then gDefaults  := specialize TDictionary<TCompressionAlgorithm, ICompressionProvider>.Create;
end;

procedure RegisterCompressionProvider(const Provider: ICompressionProvider; const Priority: Integer);
var
  Alg: TCompressionAlgorithm;
begin
  EnsureRegistry;
  Alg := Provider.Algorithm;
  // 简化：仅保留一个 Provider（优先级未用，后续可扩展为多候选）
  gProviders.AddOrSetValue(Alg, Provider);
end;

function ResolveCompressionProvider(const Algorithm: TCompressionAlgorithm): ICompressionProvider;
begin
  EnsureRegistry;
  if (gDefaults <> nil) and gDefaults.TryGetValue(Algorithm, Result) then Exit;
  if (gProviders <> nil) and gProviders.TryGetValue(Algorithm, Result) then Exit;
  Result := nil;
end;

procedure SetDefaultCompressionProvider(const Algorithm: TCompressionAlgorithm; const Provider: ICompressionProvider);
begin
  EnsureRegistry;
  gDefaults.AddOrSetValue(Algorithm, Provider);
end;

procedure ArchiverShutdown;
begin
  if gProviders <> nil then begin gProviders.Free; gProviders := nil; end;
  if gDefaults  <> nil then begin gDefaults.Free;  gDefaults  := nil; end;
end;

function DefaultArchiveOptions: TArchiveOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Format := afTar;
  Result.Compression := caNone;
  Result.CompressionLevel := 0;
  Result.Deterministic := True;
  Result.EnforcePathSafety := True;
  Result.StoreUnixPermissions := False;
  Result.StoreTimestampsUtc := True;
  Result.FollowSymlinks := False;
end;

procedure RegisterBuiltInProviders;
begin
  // 注册内建 Provider（避免在子单元初始化时引用门面符号）
  RegisterCompressionProvider(TGZipProvider.Create);
  RegisterCompressionProvider(TPaszlibDeflateProvider.Create);
end;

function CreateArchiveWriter(const Dest: TStream; const Options: TArchiveOptions): IArchiveWriter;
var
  LOut: TStream;
  LProv: ICompressionProvider;
  LProvEx: ICompressionProviderEx;
begin
  // 构建管线：optional compression -> container writer
  LOut := Dest;
  if Options.Compression <> caNone then begin
    LProv := ResolveCompressionProvider(Options.Compression);
    if LProv = nil then
      raise EArchiverError.Create('No compression provider registered for requested algorithm');
    // 优先使用带选项版本
    if Supports(LProv, ICompressionProviderEx, LProvEx) then
      LOut := LProvEx.WrapEncodeWithOptions(Dest, Options.CompressionLevel)
    else
      LOut := LProv.WrapEncode(Dest);
  end;

  case Options.Format of
    afTar:
      Result := TTarWriter.Create(LOut, Options.Deterministic, Options.EnforcePathSafety);
    afZip:
      raise EArchiverError.Create('ZIP format not yet implemented. Use TAR format with gzip compression for similar functionality.');
  else
    raise EArchiverError.Create('Unknown archive format');
  end;

  // 如果启用了压缩，使用适配器在 Finish 后释放压缩流，确保 trailer 被写入
  if (Options.Compression <> caNone) and (LOut <> Dest) then
    Result := TWriterWithOuterStream.Create(Result, LOut);
end;

function CreateArchiveReader(const Source: TStream; const Format: TArchiveFormat): IArchiveReader;
var Opt: TArchiveOptions;
begin
  Opt := DefaultArchiveOptions;
  Opt.Format := Format;
  Opt.Compression := caNone;
  Result := CreateArchiveReader(Source, Opt);
end;

function CreateArchiveReader(const Source: TStream; const Format: TArchiveFormat; const Compression: TCompressionAlgorithm): IArchiveReader;
var Opt: TArchiveOptions;
begin
  Opt := DefaultArchiveOptions;
  Opt.Format := Format;
  Opt.Compression := Compression;
  Result := CreateArchiveReader(Source, Opt);
end;

function CreateArchiveReader(const Source: TStream; const Options: TArchiveOptions): IArchiveReader;
var
  LIn: TStream;
  LProv: ICompressionProvider;
begin
  // 暂只支持 Tar 将 EnforcePathSafety 传入 Reader，其它格式后续接入
  case Options.Format of
    afTar:
      begin
        LIn := Source;
        if Options.Compression <> caNone then begin
          LProv := ResolveCompressionProvider(Options.Compression);
          if LProv = nil then raise EArchiverError.Create('No compression provider for reader');
          LIn := LProv.WrapDecode(Source);
        end;
        Result := TTarReader.Create(LIn, (LIn <> Source), Options.EnforcePathSafety);
      end;
    afZip:
      raise EArchiverError.Create('ZIP format not yet implemented. Use TAR format with gzip compression for similar functionality.');
  else
    raise EArchiverError.Create('Unknown archive format');
  end;
end;
// helper for readers/writers if they choose to enforce path safety
procedure ApplyPathSafetyEnforcement(const Safety: Boolean; const Name: string);
var norm: string;
begin
  if not Safety then Exit;
  if Name <> '' then begin
    norm := StringReplace(Name, '\', '/', [rfReplaceAll]);
    if (Length(norm) > 0) and ((norm[1] = '/') or (Pos('/../', '/' + norm + '/') > 0)) then
      raise EArchiverError.Create('unsafe path');
  end;
end;


initialization
  RegisterBuiltInProviders;

finalization
  if gProviders <> nil then begin gProviders.Free; gProviders := nil; end;
  if gDefaults  <> nil then begin gDefaults.Free;  gDefaults  := nil; end;

end.


