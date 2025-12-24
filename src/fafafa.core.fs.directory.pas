unit fafafa.core.fs.directory;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.directory - 目录操作

  从 highlevel.pas 拆分，包含：
  - DirectoryExists - 检查目录是否存在
  - CreateDirectory - 创建目录（支持递归）
  - DeleteDirectory - 删除目录（支持递归）
  - DeleteFile - 删除文件
  - GetFileSize - 获取文件大小
  - GetFileModificationTime - 获取文件修改时间
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.errors;

// 目录存在检查
function DirectoryExists(const aPath: string): Boolean;

// 创建目录
// aRecursive=True 时递归创建父目录
procedure CreateDirectory(const aPath: string; aRecursive: Boolean = False);

// 删除文件
procedure DeleteFile(const aPath: string);

// 删除目录
// aRecursive=True 时递归删除目录内容
procedure DeleteDirectory(const aPath: string; aRecursive: Boolean = False);

// 获取文件大小
function GetFileSize(const aPath: string): Int64;

// 获取文件修改时间
function GetFileModificationTime(const aPath: string): TDateTime;

implementation

uses
  DateUtils;

function DirectoryExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFDIR);
end;

procedure CreateDirectory(const aPath: string; aRecursive: Boolean);
var
  LParentPath: string;
begin
  if aRecursive then
  begin
    // 递归创建父目录
    LParentPath := ExtractFileDir(aPath);
    if (LParentPath <> '') and (LParentPath <> aPath) and not DirectoryExists(LParentPath) then
      CreateDirectory(LParentPath, True);
  end;

  // 如果目录已存在，不报错
  if not DirectoryExists(aPath) then
    CheckFsResult(fs_mkdir(aPath, S_IRWXU), 'create directory');
end;

procedure DeleteFile(const aPath: string);
begin
  CheckFsResult(fs_unlink(aPath), 'delete file');
end;

procedure DeleteDirectory(const aPath: string; aRecursive: Boolean);
var
  LDirEntries: TStringList;
  LEntry: string;
  LFullPath: string;
  LStat: TfsStat;
  I: Integer;
begin
  if aRecursive then
  begin
    // 递归删除目录内容
    LDirEntries := TStringList.Create;
    try
      if fs_scandir(aPath, LDirEntries) = 0 then
      begin
        for I := 0 to LDirEntries.Count - 1 do
        begin
          LEntry := LDirEntries[I];
          if (LEntry = '.') or (LEntry = '..') then
            Continue;

          LFullPath := IncludeTrailingPathDelimiter(aPath) + LEntry;

          if fs_stat(LFullPath, LStat) = 0 then
          begin
            if (LStat.Mode and S_IFMT) = S_IFDIR then
              DeleteDirectory(LFullPath, True)  // 递归删除子目录
            else
              DeleteFile(LFullPath);  // 删除文件
          end;
        end;
      end;
    finally
      LDirEntries.Free;
    end;
  end;

  CheckFsResult(fs_rmdir(aPath), 'delete directory');
end;

function GetFileSize(const aPath: string): Int64;
var
  LStat: TfsStat;
begin
  CheckFsResult(fs_stat(aPath, LStat), 'get file size');
  Result := LStat.Size;
end;

function GetFileModificationTime(const aPath: string): TDateTime;
var
  LStat: TfsStat;
  Base: TDateTime;
begin
  CheckFsResult(fs_stat(aPath, LStat), 'get file modification time');
  // 正确实现：将 Unix 时间（秒+纳秒）转换为 TDateTime（UTC 基准）
  Base := UnixToDateTime(LStat.MTime.Sec, True);
  Result := Base + (LStat.MTime.Nsec / 1e9) / 86400.0; // 纳秒的小数部分换算为天
end;

end.
