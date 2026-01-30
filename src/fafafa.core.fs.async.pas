unit fafafa.core.fs.async;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.thread,
  fafafa.core.fs,
  fafafa.core.fs.path;

type
  // 异步文件系统接口
  IAsyncFileSystem = interface(IInterface)
  ['{6472FCC2-7275-45A0-93EE-A4B7EF460385}']
    // 基于Future的异步操作
    function ReadFileAsync(const aPath: string): IFuture<TBytes>;
    function WriteFileAsync(const aPath: string; const aData: TBytes): IFuture<Boolean>;
    function ReadTextAsync(const aPath: string; aEncoding: TEncoding = nil): IFuture<string>;
    function WriteTextAsync(const aPath: string; const aText: string; aEncoding: TEncoding = nil): IFuture<Boolean>;
    
    function StatAsync(const aPath: string): IFuture<TFileStat>;
    function ExistsAsync(const aPath: string): IFuture<Boolean>;
    function DeleteAsync(const aPath: string): IFuture<Boolean>;
    function CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
    
    function IsFileAsync(const aPath: string): IFuture<Boolean>;
    function IsDirectoryAsync(const aPath: string): IFuture<Boolean>;
    function FileSizeAsync(const aPath: string): IFuture<Int64>;
    
    function CreateDirectoryAsync(const aPath: string; aMode: Integer = 755): IFuture<Boolean>;
    function RemoveDirectoryAsync(const aPath: string): IFuture<Boolean>;
    function RenameAsync(const aOldPath, aNewPath: string): IFuture<Boolean>;
    
    // 线程池配置
    function GetThreadPool: IThreadPool;
    procedure SetThreadPool(aPool: IThreadPool);
  end;

  // 异步文件句柄接口
  IAsyncFile = interface(IInterface)
  ['{DC4E3160-2DDB-4482-8C19-9A6E94758859}']    
    function ReadAsync(aSize: SizeUInt): IFuture<TBytes>;
    function WriteAsync(const aData: TBytes): IFuture<SizeUInt>;
    function SeekAsync(aOffset: Int64; aWhence: Integer): IFuture<Int64>;
    function FlushAsync: IFuture<Boolean>;
    function CloseAsync: IFuture<Boolean>;
    
    // 便利方法
    function ReadAllAsync: IFuture<TBytes>;
    function ReadStringAsync(aEncoding: TEncoding = nil): IFuture<string>;
    function WriteStringAsync(const aText: string; aEncoding: TEncoding = nil): IFuture<SizeUInt>;
    
    // 获取底层同步句柄
    function GetSyncHandle: TFileHandle;
    function GetPath: string;
  end;

  // 异步文件系统实现
  TAsyncFileSystem = class(TInterfacedObject, IAsyncFileSystem)
  private
    FThreadPool: IThreadPool;
    FOwnsThreadPool: Boolean;
  public
    constructor Create(aThreadPool: IThreadPool = nil);
    destructor Destroy; override;
    
    // IAsyncFileSystem 接口实现
    function ReadFileAsync(const aPath: string): IFuture<TBytes>;
    function WriteFileAsync(const aPath: string; const aData: TBytes): IFuture<Boolean>;
    function ReadTextAsync(const aPath: string; aEncoding: TEncoding = nil): IFuture<string>;
    function WriteTextAsync(const aPath: string; const aText: string; aEncoding: TEncoding = nil): IFuture<Boolean>;
    
    function StatAsync(const aPath: string): IFuture<TFileStat>;
    function ExistsAsync(const aPath: string): IFuture<Boolean>;
    function DeleteAsync(const aPath: string): IFuture<Boolean>;
    function CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
    
    function IsFileAsync(const aPath: string): IFuture<Boolean>;
    function IsDirectoryAsync(const aPath: string): IFuture<Boolean>;
    function FileSizeAsync(const aPath: string): IFuture<Int64>;
    
    function CreateDirectoryAsync(const aPath: string; aMode: Integer = 755): IFuture<Boolean>;
    function RemoveDirectoryAsync(const aPath: string): IFuture<Boolean>;
    function RenameAsync(const aOldPath, aNewPath: string): IFuture<Boolean>;
    
    function GetThreadPool: IThreadPool;
    procedure SetThreadPool(aPool: IThreadPool);
  end;

  // 异步文件句柄实现
  TAsyncFile = class(TInterfacedObject, IAsyncFile)
  private
    FHandle: TFileHandle;
    FPath: string;
    FThreadPool: IThreadPool;
    FClosed: Boolean;
  public
    constructor Create(aHandle: TFileHandle; const aPath: string; aThreadPool: IThreadPool);
    destructor Destroy; override;
    
    // IAsyncFile 接口实现
    function ReadAsync(aSize: SizeUInt): IFuture<TBytes>;
    function WriteAsync(const aData: TBytes): IFuture<SizeUInt>;
    function SeekAsync(aOffset: Int64; aWhence: Integer): IFuture<Int64>;
    function FlushAsync: IFuture<Boolean>;
    function CloseAsync: IFuture<Boolean>;
    
    function ReadAllAsync: IFuture<TBytes>;
    function ReadStringAsync(aEncoding: TEncoding = nil): IFuture<string>;
    function WriteStringAsync(const aText: string; aEncoding: TEncoding = nil): IFuture<SizeUInt>;
    
    function GetSyncHandle: TFileHandle;
    function GetPath: string;
  end;

// 工厂函数
function CreateAsyncFileSystem(aThreadPool: IThreadPool = nil): IAsyncFileSystem;
function OpenFileAsync(const aPath: string; aFlags: Integer; aMode: Integer = 644; 
  aThreadPool: IThreadPool = nil): IFuture<IAsyncFile>;

implementation

// TAsyncFileSystem 实现

constructor TAsyncFileSystem.Create(aThreadPool: IThreadPool);
begin
  inherited Create;
  if aThreadPool = nil then
  begin
    FThreadPool := CreateThreadPool(2, 8, 30000); // 专用文件I/O线程池
    FThreadPool.Start;
    FOwnsThreadPool := True;
  end
  else
  begin
    FThreadPool := aThreadPool;
    FOwnsThreadPool := False;
  end;
end;

destructor TAsyncFileSystem.Destroy;
begin
  if FOwnsThreadPool and Assigned(FThreadPool) then
  begin
    FThreadPool.Shutdown(True);
    FThreadPool := nil;
  end;
  inherited Destroy;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TAsyncFileSystem.ReadFileAsync(const aPath: string): IFuture<TBytes>;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise ECore.Create('Invalid or unsafe path: ' + aPath);

  var PathCopy := aPath;
  Result := FThreadPool.Submit<TBytes>(
    function: TBytes
    begin
      Result := fs_read_file(PathCopy);
    end
  );
end;

function TAsyncFileSystem.WriteFileAsync(const aPath: string; const aData: TBytes): IFuture<Boolean>;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise ECore.Create('Invalid or unsafe path: ' + aPath);

  var PathCopy := aPath;
  var DataCopy := Copy(aData);

  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_write_file(PathCopy, DataCopy);
    end
  );
end;

function TAsyncFileSystem.ReadTextAsync(const aPath: string; aEncoding: TEncoding): IFuture<string>;
begin
  var PathCopy := aPath;
  var EncodingCopy := aEncoding;
  
  Result := FThreadPool.Submit<string>(
    function: string
    begin
      Result := fs_read_text(PathCopy, EncodingCopy);
    end
  );
end;

function TAsyncFileSystem.WriteTextAsync(const aPath: string; const aText: string; aEncoding: TEncoding): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  var TextCopy := aText;
  var EncodingCopy := aEncoding;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_write_text(PathCopy, TextCopy, EncodingCopy);
    end
  );
end;

function TAsyncFileSystem.StatAsync(const aPath: string): IFuture<TFileStat>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<TFileStat>(
    function: TFileStat
    begin
      if fs_stat(PathCopy, Result) <> 0 then
        raise ECore.Create('Failed to get file stat for: ' + PathCopy);
    end
  );
end;

function TAsyncFileSystem.ExistsAsync(const aPath: string): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_exists(PathCopy);
    end
  );
end;

function TAsyncFileSystem.DeleteAsync(const aPath: string): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_unlink(PathCopy) = 0;
    end
  );
end;

function TAsyncFileSystem.CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
begin
  var SrcCopy := aSrc;
  var DestCopy := aDest;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_copyfile(SrcCopy, DestCopy, 0) = 0;
    end
  );
end;

function TAsyncFileSystem.IsFileAsync(const aPath: string): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_is_file(PathCopy);
    end
  );
end;

function TAsyncFileSystem.IsDirectoryAsync(const aPath: string): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_is_directory(PathCopy);
    end
  );
end;

function TAsyncFileSystem.FileSizeAsync(const aPath: string): IFuture<Int64>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Int64>(
    function: Int64
    begin
      Result := fs_file_size(PathCopy);
    end
  );
end;

function TAsyncFileSystem.CreateDirectoryAsync(const aPath: string; aMode: Integer): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  var ModeCopy := aMode;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_mkdir(PathCopy, ModeCopy) = 0;
    end
  );
end;

function TAsyncFileSystem.RemoveDirectoryAsync(const aPath: string): IFuture<Boolean>;
begin
  var PathCopy := aPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_rmdir(PathCopy) = 0;
    end
  );
end;

function TAsyncFileSystem.RenameAsync(const aOldPath, aNewPath: string): IFuture<Boolean>;
begin
  var OldPathCopy := aOldPath;
  var NewPathCopy := aNewPath;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_rename(OldPathCopy, NewPathCopy) = 0;
    end
  );
end;
{$ELSE}
// 如果不支持匿名函数，则抛出异常
function TAsyncFileSystem.ReadFileAsync(const aPath: string): IFuture<TBytes>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.WriteFileAsync(const aPath: string; const aData: TBytes): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.ReadTextAsync(const aPath: string; aEncoding: TEncoding): IFuture<string>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.WriteTextAsync(const aPath: string; const aText: string; aEncoding: TEncoding): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.StatAsync(const aPath: string): IFuture<TFileStat>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.ExistsAsync(const aPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.DeleteAsync(const aPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.IsFileAsync(const aPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.IsDirectoryAsync(const aPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.FileSizeAsync(const aPath: string): IFuture<Int64>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.CreateDirectoryAsync(const aPath: string; aMode: Integer): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.RemoveDirectoryAsync(const aPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFileSystem.RenameAsync(const aOldPath, aNewPath: string): IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;
{$ENDIF}

function TAsyncFileSystem.GetThreadPool: IThreadPool;
begin
  Result := FThreadPool;
end;

procedure TAsyncFileSystem.SetThreadPool(aPool: IThreadPool);
begin
  if FOwnsThreadPool and Assigned(FThreadPool) then
  begin
    FThreadPool.Shutdown(True);
  end;
  
  FThreadPool := aPool;
  FOwnsThreadPool := False;
end;

// TAsyncFile 实现

constructor TAsyncFile.Create(aHandle: TFileHandle; const aPath: string; aThreadPool: IThreadPool);
begin
  inherited Create;
  FHandle := aHandle;
  FPath := aPath;
  FThreadPool := aThreadPool;
  FClosed := False;
end;

destructor TAsyncFile.Destroy;
begin
  if not FClosed then
    fs_close(FHandle);
  inherited Destroy;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TAsyncFile.ReadAsync(aSize: SizeUInt): IFuture<TBytes>;
begin
  if FClosed then
    raise ECore.Create('File is closed');

  var Handle := FHandle;
  var Size := aSize;

  Result := FThreadPool.Submit<TBytes>(
    function: TBytes
    var
      BytesRead: Integer;
    begin
      SetLength(Result, Size);
      BytesRead := fs_read(Handle, Result[0], Size, -1);
      if BytesRead < 0 then
        raise ECore.Create('Failed to read from file');
      SetLength(Result, BytesRead);
    end
  );
end;

function TAsyncFile.WriteAsync(const aData: TBytes): IFuture<SizeUInt>;
begin
  if FClosed then
    raise ECore.Create('File is closed');

  var Handle := FHandle;
  var DataCopy := Copy(aData);

  Result := FThreadPool.Submit<SizeUInt>(
    function: SizeUInt
    var
      BytesWritten: Integer;
    begin
      BytesWritten := fs_write(Handle, DataCopy[0], Length(DataCopy), -1);
      if BytesWritten < 0 then
        raise ECore.Create('Failed to write to file');
      Result := BytesWritten;
    end
  );
end;

function TAsyncFile.SeekAsync(aOffset: Int64; aWhence: Integer): IFuture<Int64>;
begin
  if FClosed then
    raise ECore.Create('File is closed');

  var Handle := FHandle;
  var Offset := aOffset;
  var Whence := aWhence;

  Result := FThreadPool.Submit<Int64>(
    function: Int64
    begin
      Result := fs_seek(Handle, Offset, Whence);
      if Result < 0 then
        raise ECore.Create('Failed to seek in file');
    end
  );
end;

function TAsyncFile.FlushAsync: IFuture<Boolean>;
begin
  if FClosed then
    raise ECore.Create('File is closed');

  var Handle := FHandle;

  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_fsync(Handle) = 0;
    end
  );
end;

function TAsyncFile.CloseAsync: IFuture<Boolean>;
begin
  // ✅ 设计说明：FClosed 在提交关闭任务后立即设置为 True
  // 这是有意为之的设计：
  // 1. 防止在关闭过程中有新的读写操作
  // 2. 句柄已被捕获到闭包中，析构函数不需要再次关闭
  // 3. 如果需要等待关闭完成，调用方应使用 CloseAsync.Await
  if FClosed then
  begin
    Result := FThreadPool.Submit<Boolean>(
      function: Boolean
      begin
        Result := True;
      end
    );
    Exit;
  end;

  // 立即标记为关闭，防止后续操作
  FClosed := True;

  var Handle := FHandle;

  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      Result := fs_close(Handle) = 0;
    end
  );
end;

function TAsyncFile.ReadAllAsync: IFuture<TBytes>;
begin
  if FClosed then
    raise ECore.Create('File is closed');

  var Handle := FHandle;

  Result := FThreadPool.Submit<TBytes>(
    function: TBytes
    var
      Stat: TFileStat;
      BytesRead: Integer;
    begin
      // 获取文件大小
      if fs_fstat(Handle, Stat) <> 0 then
        raise ECore.Create('Failed to get file stat');

      if Stat.Size <= 0 then
      begin
        SetLength(Result, 0);
        Exit;
      end;

      SetLength(Result, Stat.Size);
      BytesRead := fs_read(Handle, Result[0], Stat.Size, 0);
      if BytesRead < 0 then
        raise ECore.Create('Failed to read file');

      SetLength(Result, BytesRead);
    end
  );
end;

function TAsyncFile.ReadStringAsync(aEncoding: TEncoding): IFuture<string>;
begin
  var EncodingCopy := aEncoding;

  Result := ReadAllAsync.Then<string>(
    function(const Data: TBytes): string
    begin
      if EncodingCopy = nil then
        EncodingCopy := TEncoding.UTF8;
      Result := EncodingCopy.GetString(Data);
    end
  );
end;

function TAsyncFile.WriteStringAsync(const aText: string; aEncoding: TEncoding): IFuture<SizeUInt>;
begin
  var TextCopy := aText;
  var EncodingCopy := aEncoding;

  if EncodingCopy = nil then
    EncodingCopy := TEncoding.UTF8;

  var Data := EncodingCopy.GetBytes(TextCopy);
  Result := WriteAsync(Data);
end;
{$ELSE}
// 如果不支持匿名函数，则抛出异常
function TAsyncFile.ReadAsync(aSize: SizeUInt): IFuture<TBytes>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.WriteAsync(const aData: TBytes): IFuture<SizeUInt>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.SeekAsync(aOffset: Int64; aWhence: Integer): IFuture<Int64>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.FlushAsync: IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.CloseAsync: IFuture<Boolean>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.ReadAllAsync: IFuture<TBytes>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.ReadStringAsync(aEncoding: TEncoding): IFuture<string>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;

function TAsyncFile.WriteStringAsync(const aText: string; aEncoding: TEncoding): IFuture<SizeUInt>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;
{$ENDIF}

function TAsyncFile.GetSyncHandle: TFileHandle;
begin
  Result := FHandle;
end;

function TAsyncFile.GetPath: string;
begin
  Result := FPath;
end;

// 工厂函数实现

function CreateAsyncFileSystem(aThreadPool: IThreadPool): IAsyncFileSystem;
begin
  Result := TAsyncFileSystem.Create(aThreadPool);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function OpenFileAsync(const aPath: string; aFlags: Integer; aMode: Integer;
  aThreadPool: IThreadPool): IFuture<IAsyncFile>;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise ECore.Create('Invalid or unsafe path: ' + aPath);

  if aThreadPool = nil then
    aThreadPool := GetDefaultThreadPool;

  var PathCopy := aPath;
  var FlagsCopy := aFlags;
  var ModeCopy := aMode;
  var ThreadPoolCopy := aThreadPool;

  Result := aThreadPool.Submit<IAsyncFile>(
    function: IAsyncFile
    var
      Handle: TFileHandle;
    begin
      Handle := fs_open(PathCopy, FlagsCopy, ModeCopy);
      if Handle < 0 then
        raise ECore.Create('Failed to open file: ' + PathCopy);

      Result := TAsyncFile.Create(Handle, PathCopy, ThreadPoolCopy);
    end
  );
end;
{$ELSE}
function OpenFileAsync(const aPath: string; aFlags: Integer; aMode: Integer;
  aThreadPool: IThreadPool): IFuture<IAsyncFile>;
begin
  raise ENotSupported.Create('Async file operations require anonymous function support (FPC 3.3.1+)');
end;
{$ENDIF}

end.
