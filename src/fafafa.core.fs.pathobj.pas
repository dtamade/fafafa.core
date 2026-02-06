unit fafafa.core.fs.pathobj;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch advancedrecords}

{!
  fafafa.core.fs.pathobj - Rust 风格的 Path/PathBuf 包装

  对标 Rust std::path::Path 和 PathBuf，提供：
  - TFsPath: 不可变路径引用（类似 Rust Path）
  - TFsPathBuf: 可变路径缓冲区（类似 Rust PathBuf）

  用法示例：
    var
      P: TFsPath;
      Buf: TFsPathBuf;
    begin
      // 不可变路径
      P := TFsPath.From('/home/user/data.txt');
      WriteLn(P.FileName);      // 'data.txt'
      WriteLn(P.Extension);     // '.txt'
      WriteLn(P.Parent.Value);  // '/home/user'

      // 可变路径缓冲区
      Buf := TFsPathBuf.From('/home/user');
      Buf.Push('documents');
      Buf.Push('file.txt');
      WriteLn(Buf.AsPath.Value); // '/home/user/documents/file.txt'

      // 链式操作
      P := TFsPath.From('/path/to/file.txt')
             .WithExtension('.bak');
    end;
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs.path,
  fafafa.core.fs.types;

type
  // ============================================================================
  // TFsPath - 不可变路径（对标 Rust std::path::Path）
  // 必须先声明，因为 TFsPathBuf 的方法需要返回 TFsPath
  // ============================================================================
  TFsPath = record
  private
    FValue: string;
  public
    // 构造
    class function From(const APath: string): TFsPath; static;
    class function Current: TFsPath; static;
    class function Temp: TFsPath; static;
    class function Home: TFsPath; static;

    // 属性访问
    function Value: string;
    function AsStr: string;
    function IsEmpty: Boolean;

    // 组件访问
    function FileName: string;
    function FileStem: string;
    function Extension: string;
    function Parent: TFsPath;

    // 路径判断
    function IsAbsolute: Boolean;
    function IsRelative: Boolean;
    function Exists: Boolean;
    function IsFile: Boolean;
    function IsDir: Boolean;
    function IsSymlink: Boolean;

    // 路径转换
    function ToAbsolute: TFsPath;
    function Canonicalize: TFsPath;
    function WithFileName(const AName: string): TFsPath;
    function WithExtension(const AExt: string): TFsPath;

    // 路径连接
    function Join(const APath: string): TFsPath;
    function Join(const AOther: TFsPath): TFsPath;

    // 相对路径
    function RelativeTo(const ABase: string): TFsPath;
    function RelativeTo(const ABase: TFsPath): TFsPath;
    function StartsWith(const APrefix: string): Boolean;
    function StartsWith(const APrefix: TFsPath): Boolean;

    // 元数据
    function Metadata: TFsMetadata;

    // 组件迭代
    function Components: TStringArray;
    function Depth: Integer;

    // 比较
    function Equals(const AOther: TFsPath): Boolean;
    function Equals(const AOther: string): Boolean;
  end;

  // ============================================================================
  // TFsPathBuf - 可变路径缓冲区（对标 Rust std::path::PathBuf）
  // ============================================================================
  TFsPathBuf = record
  private
    FValue: string;
  public
    // 构造
    class function New: TFsPathBuf; static;
    class function From(const APath: string): TFsPathBuf; static;
    class function FromPath(const APath: TFsPath): TFsPathBuf; static;

    // 属性
    function Value: string;
    function IsEmpty: Boolean;

    // 修改操作
    procedure Push(const APath: string);
    procedure PushPath(const APath: TFsPath);
    function Pop: Boolean;
    procedure SetFileName(const AName: string);
    procedure SetExtension(const AExt: string);
    procedure Clear;

    // 转换为不可变路径
    function AsPath: TFsPath;

    // 获取内容
    function FileName: string;
    function Extension: string;
    function Parent: TFsPath;
  end;

  // ============================================================================
  // TFsPathHelper - 为 TFsPath 添加 ToPathBuf 方法
  // 使用 type helper 解决循环引用问题
  // ============================================================================
  TFsPathHelper = record helper for TFsPath
    function ToPathBuf: TFsPathBuf;
  end;

// ============================================================================
// 便捷函数
// ============================================================================

// 快速创建路径
function Path(const APath: string): TFsPath; inline;
function PathBuf(const APath: string): TFsPathBuf; inline;

implementation

// ============================================================================
// TFsPath
// ============================================================================

class function TFsPath.From(const APath: string): TFsPath;
begin
  Result.FValue := APath;
end;

class function TFsPath.Current: TFsPath;
begin
  Result.FValue := GetCurrentDirectory;
end;

class function TFsPath.Temp: TFsPath;
begin
  Result.FValue := GetTempDirectory;
end;

class function TFsPath.Home: TFsPath;
begin
  Result.FValue := GetHomeDirectory;
end;

function TFsPath.Value: string;
begin
  Result := FValue;
end;

function TFsPath.AsStr: string;
begin
  Result := FValue;
end;

function TFsPath.IsEmpty: Boolean;
begin
  Result := FValue = '';
end;

function TFsPath.FileName: string;
begin
  Result := ExtractFileName(FValue);
end;

function TFsPath.FileStem: string;
begin
  Result := ExtractBaseName(FValue);
end;

function TFsPath.Extension: string;
begin
  Result := ExtractFileExtension(FValue);
end;

function TFsPath.Parent: TFsPath;
begin
  Result.FValue := GetParentPath(FValue);
end;

function TFsPath.IsAbsolute: Boolean;
begin
  Result := IsAbsolutePath(FValue);
end;

function TFsPath.IsRelative: Boolean;
begin
  Result := IsRelativePath(FValue);
end;

function TFsPath.Exists: Boolean;
begin
  Result := PathExists(FValue);
end;

function TFsPath.IsFile: Boolean;
begin
  Result := GetPathType(FValue) = ptFile;
end;

function TFsPath.IsDir: Boolean;
begin
  Result := GetPathType(FValue) = ptDirectory;
end;

function TFsPath.IsSymlink: Boolean;
begin
  Result := GetPathType(FValue) = ptSymlink;
end;

function TFsPath.ToAbsolute: TFsPath;
begin
  Result.FValue := ToAbsolutePath(FValue);
end;

function TFsPath.Canonicalize: TFsPath;
begin
  Result.FValue := fafafa.core.fs.path.Canonicalize(FValue, True);
end;

function TFsPath.WithFileName(const AName: string): TFsPath;
var
  Dir: string;
begin
  Dir := GetParentPath(FValue);
  if Dir = '' then
    Result.FValue := AName
  else
    Result.FValue := JoinPath(Dir, AName);
end;

function TFsPath.WithExtension(const AExt: string): TFsPath;
begin
  Result.FValue := ChangeExtension(FValue, AExt);
end;

function TFsPath.Join(const APath: string): TFsPath;
begin
  Result.FValue := JoinPath(FValue, APath);
end;

function TFsPath.Join(const AOther: TFsPath): TFsPath;
begin
  Result.FValue := JoinPath(FValue, AOther.FValue);
end;

function TFsPath.RelativeTo(const ABase: string): TFsPath;
begin
  Result.FValue := ToRelativePath(FValue, ABase);
end;

function TFsPath.RelativeTo(const ABase: TFsPath): TFsPath;
begin
  Result.FValue := ToRelativePath(FValue, ABase.FValue);
end;

function TFsPath.StartsWith(const APrefix: string): Boolean;
begin
  Result := IsSubPath(FValue, APrefix);
end;

function TFsPath.StartsWith(const APrefix: TFsPath): Boolean;
begin
  Result := IsSubPath(FValue, APrefix.FValue);
end;

function TFsPath.Metadata: TFsMetadata;
begin
  Result := TFsMetadata.FromPath(FValue, True);
end;

function TFsPathHelper.ToPathBuf: TFsPathBuf;
begin
  Result.FValue := FValue;
end;

function TFsPath.Components: TStringArray;
var
  List: TStringList;
  I: Integer;
begin
  Result := nil;
  List := EnumeratePathComponents(FValue);
  try
    SetLength(Result, List.Count);
    for I := 0 to List.Count - 1 do
      Result[I] := List[I];
  finally
    List.Free;
  end;
end;

function TFsPath.Depth: Integer;
begin
  Result := GetPathDepth(FValue);
end;

function TFsPath.Equals(const AOther: TFsPath): Boolean;
begin
  Result := PathsEqual(FValue, AOther.FValue);
end;

function TFsPath.Equals(const AOther: string): Boolean;
begin
  Result := PathsEqual(FValue, AOther);
end;

// ============================================================================
// TFsPathBuf
// ============================================================================

class function TFsPathBuf.New: TFsPathBuf;
begin
  Result.FValue := '';
end;

class function TFsPathBuf.From(const APath: string): TFsPathBuf;
begin
  Result.FValue := APath;
end;

class function TFsPathBuf.FromPath(const APath: TFsPath): TFsPathBuf;
begin
  Result.FValue := APath.Value;
end;

function TFsPathBuf.Value: string;
begin
  Result := FValue;
end;

function TFsPathBuf.IsEmpty: Boolean;
begin
  Result := FValue = '';
end;

procedure TFsPathBuf.Push(const APath: string);
begin
  if FValue = '' then
    FValue := APath
  else
    FValue := JoinPath(FValue, APath);
end;

procedure TFsPathBuf.PushPath(const APath: TFsPath);
begin
  Push(APath.Value);
end;

function TFsPathBuf.Pop: Boolean;
var
  NewPath: string;
begin
  NewPath := GetParentPath(FValue);
  Result := NewPath <> FValue;
  FValue := NewPath;
end;

procedure TFsPathBuf.SetFileName(const AName: string);
var
  Dir: string;
begin
  Dir := GetParentPath(FValue);
  if Dir = '' then
    FValue := AName
  else
    FValue := JoinPath(Dir, AName);
end;

procedure TFsPathBuf.SetExtension(const AExt: string);
begin
  FValue := ChangeExtension(FValue, AExt);
end;

procedure TFsPathBuf.Clear;
begin
  FValue := '';
end;

function TFsPathBuf.AsPath: TFsPath;
begin
  Result.FValue := FValue;
end;

function TFsPathBuf.FileName: string;
begin
  Result := ExtractFileName(FValue);
end;

function TFsPathBuf.Extension: string;
begin
  Result := ExtractFileExtension(FValue);
end;

function TFsPathBuf.Parent: TFsPath;
begin
  Result.FValue := GetParentPath(FValue);
end;

// ============================================================================
// 便捷函数
// ============================================================================

function Path(const APath: string): TFsPath;
begin
  Result := TFsPath.From(APath);
end;

function PathBuf(const APath: string): TFsPathBuf;
begin
  Result := TFsPathBuf.From(APath);
end;

end.
