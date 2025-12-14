unit fafafa.core.io.files;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.files - 文件系统 IO 适配
  
  提供安全的文件打开/创建函数，将 OS 异常映射为统一的 EIOError。
}

interface

uses
  Classes, SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.error,
  fafafa.core.io.streams;

type
  { TFileOpenOptions/Builder }
  TFileOpenOptions = record
    Path: string;
    Read: Boolean;
    Write: Boolean;
    Create_: Boolean;
    CreateNew: Boolean;
    Truncate: Boolean;
    Append: Boolean;
  end;

  TFileOpenBuilder = record
    private
      F: TFileOpenOptions;
    public
      class function ForPath(const APath: string): TFileOpenBuilder; static;
      function ReadOnly: TFileOpenBuilder; inline;
      function ReadWrite: TFileOpenBuilder; inline;
      function Create_: TFileOpenBuilder; inline;
      function CreateNew: TFileOpenBuilder; inline;
      function Truncate: TFileOpenBuilder; inline;
      function Append: TFileOpenBuilder; inline;
      function Open: IReadWriteSeeker;
  end;

{ 打开文件进行读取 }
function OpenFile(const Path: string): IReadSeeker;

{ 创建或截断文件进行写入 }
function CreateFile(const Path: string): IWriteSeeker;

{ 以指定模式打开文件 }
function OpenFileMode(const Path: string; Mode: Word): IReadWriteSeeker;

{ Builder 入口与快捷族 }
function FileOpen(const Path: string): TFileOpenBuilder;
function OpenRead(const Path: string): IReadSeeker;      // 只读
function CreateTruncate(const Path: string): IWriteSeeker; // 截断写
function OpenAppend(const Path: string): IWriteSeeker;    // 追加写

implementation

function _OpenRW(const Opt: TFileOpenOptions): IReadWriteSeeker;
var
  Mode: LongInt;
  FS: TFileStream;
begin
  // CreateNew: 如果文件已存在则抛 AlreadyExists（在打开文件前检查）
  if Opt.CreateNew and FileExists(Opt.Path) then
    raise EIOError.Create(ekAlreadyExists, 'create', Opt.Path, 0, 'already exists');

  // 基于选项构造 Mode（FPC/Classes 标志）
  // 优先级：CreateNew > Create_ > Truncate > Append > Read/Write
  if Opt.CreateNew then
    Mode := fmCreate or fmShareDenyWrite  // 创建新文件（已检查不存在）
  else if Opt.Create_ then
    Mode := fmCreate or fmShareDenyWrite  // 创建或打开并截断
  else if Opt.Truncate then
    Mode := fmCreate or fmShareDenyWrite  // fmCreate 本身会截断
  else if Opt.Append then
    Mode := fmOpenReadWrite               // 追加需要先打开再 Seek 到末尾
  else if Opt.Read and (not Opt.Write) then
    Mode := fmOpenRead
  else if Opt.Write and (not Opt.Read) then
    Mode := fmOpenWrite
  else
    Mode := fmOpenReadWrite;

  try
    FS := TFileStream.Create(Opt.Path, Mode);

    // 处理 Append：Seek 到末尾
    if Opt.Append then
      FS.Position := FS.Size;

    Result := IOFromStream(FS, True);
  except
    on E: EIOError do
      raise;  // 已经是 EIOError，直接重抛
    on E: EFOpenError do
      raise IOErrorWrap(ekNotFound, 'open', Opt.Path, E);
    on E: EFCreateError do
      raise IOErrorWrap(ekPermissionDenied, 'create', Opt.Path, E);
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'open', Opt.Path, E);
  end;
end;

function FileOpen(const Path: string): TFileOpenBuilder;
begin
  Result := TFileOpenBuilder.ForPath(Path);
end;

class function TFileOpenBuilder.ForPath(const APath: string): TFileOpenBuilder;
begin
  Result := Default(TFileOpenBuilder);
  Result.F.Path := APath;
  // 默认 ReadOnly
  Result.F.Read := True;
end;

function TFileOpenBuilder.ReadOnly: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.Read := True;
  Result.F.Write := False;
  Result.F.Create_ := False;
  Result.F.CreateNew := False;
  Result.F.Truncate := False;
  Result.F.Append := False;
end;

function TFileOpenBuilder.ReadWrite: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.Read := True;
  Result.F.Write := True;
end;

function TFileOpenBuilder.Create_: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.Create_ := True;
end;

function TFileOpenBuilder.CreateNew: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.CreateNew := True;
end;

function TFileOpenBuilder.Truncate: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.Truncate := True;
end;

function TFileOpenBuilder.Append: TFileOpenBuilder;
begin
  Result := Self;
  Result.F.Append := True;
end;

function TFileOpenBuilder.Open: IReadWriteSeeker;
begin
  Result := _OpenRW(F);
end;

function OpenRead(const Path: string): IReadSeeker;
begin
  Result := OpenFile(Path);
end;

function CreateTruncate(const Path: string): IWriteSeeker;
begin
  // 直接使用 Create (截断)
  Result := CreateFile(Path);
end;

function OpenAppend(const Path: string): IWriteSeeker;
var
  RW: IReadWriteSeeker;
begin
  RW := FileOpen(Path).ReadWrite.Append.Open;
  Result := RW as IWriteSeeker;
end;

// 旧辅助：保留注释
// 辅助：捕获异常并映射
procedure WrapFileOp(const OpName: string; Proc: TProcedure);
begin
  try
    Proc;
  except
    on E: EFOpenError do
      raise EIOError.Create(ekNotFound, OpName + ': ' + E.Message);
    on E: EFCreateError do
      raise EIOError.Create(ekPermissionDenied, OpName + ': ' + E.Message);
    on E: Exception do
      raise EIOError.Create(ekUnknown, OpName + ': ' + E.Message);
  end;
end;

// 上面的辅助很难用，因为 TFileStream.Create 是构造函数
// 我们直接在函数里写 try..except

function OpenFile(const Path: string): IReadSeeker;
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
    Result := IOFromStream(FS, True) as IReadSeeker;
  except
    on E: EFOpenError do
      raise IOErrorWrap(ekNotFound, 'open', Path, E);
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'open', Path, E);
  end;
end;

function CreateFile(const Path: string): IWriteSeeker;
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(Path, fmCreate or fmShareDenyWrite);
    Result := IOFromStream(FS, True) as IWriteSeeker;
  except
    on E: EFCreateError do
      raise IOErrorWrap(ekPermissionDenied, 'create', Path, E);
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'create', Path, E);
  end;
end;

function OpenFileMode(const Path: string; Mode: Word): IReadWriteSeeker;
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(Path, Mode);
    Result := IOFromStream(FS, True);
  except
    on E: EFOpenError do
      raise IOErrorWrap(ekNotFound, 'open', Path, E);
    on E: EFCreateError do
      raise IOErrorWrap(ekPermissionDenied, 'create', Path, E);
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'open', Path, E);
  end;
end;

end.
