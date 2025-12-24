unit fafafa.core.fs.provider.memory;

{$mode objfpc}{$H+}

{!
  TMemoryFileSystem - 内存文件系统实现

  用于单元测试和 Mock 场景，所有文件操作在内存中进行。

  使用示例:
    var
      FS: IFileSystemProvider;
    begin
      FS := TMemoryFileSystem.Create;
      FS.WriteTextFile('/test.txt', 'Hello World');
      WriteLn(FS.ReadTextFile('/test.txt'));  // 输出: Hello World
    end;
}

interface

uses
  SysUtils, Classes, Contnrs,
  fafafa.core.fs.provider;

type
  { 内存文件节点 }
  TMemoryFileNode = class
  public
    Name: string;
    IsDirectory: Boolean;
    Data: TBytes;
    ModificationTime: TDateTime;
    Children: TFPObjectList;  // TMemoryFileNode

    constructor Create(const AName: string; AIsDirectory: Boolean);
    destructor Destroy; override;
    function FindChild(const AName: string): TMemoryFileNode;
    procedure AddChild(ANode: TMemoryFileNode);
    procedure RemoveChild(ANode: TMemoryFileNode);
  end;

  { 内存文件系统 }
  TMemoryFileSystem = class(TInterfacedObject, IFileSystemProvider)
  private
    FRoot: TMemoryFileNode;
    FCurrentDir: string;
    FTempDir: string;

    function NormalizePath(const APath: string): string;
    function FindNode(const APath: string; ACreateParents: Boolean = False): TMemoryFileNode;
    function GetParentNode(const APath: string; out ChildName: string): TMemoryFileNode;
  public
    constructor Create;
    destructor Destroy; override;

    // 文件操作
    function ReadFile(const APath: string): TBytes;
    function ReadTextFile(const APath: string): string;
    procedure WriteFile(const APath: string; const AData: TBytes);
    procedure WriteTextFile(const APath: string; const AText: string);
    procedure WriteFileAtomic(const APath: string; const AData: TBytes);
    procedure DeleteFile(const APath: string);
    procedure CopyFile(const ASrc, ADst: string; AOverwrite: Boolean = False);
    procedure MoveFile(const ASrc, ADst: string; AOverwrite: Boolean = False);

    // 目录操作
    procedure CreateDirectory(const APath: string; ARecursive: Boolean = True);
    procedure DeleteDirectory(const APath: string; ARecursive: Boolean = False);
    function ListDirectory(const APath: string): TFsDirEntries;

    // 存在性检查
    function Exists(const APath: string): Boolean;
    function IsFile(const APath: string): Boolean;
    function IsDirectory(const APath: string): Boolean;
    function IsSymlink(const APath: string): Boolean;

    // 元数据
    function GetFileInfo(const APath: string): TFsFileInfo;
    function GetFileSize(const APath: string): Int64;
    function GetModificationTime(const APath: string): TDateTime;
    procedure SetModificationTime(const APath: string; ATime: TDateTime);

    // 路径操作
    function GetCurrentDirectory: string;
    procedure SetCurrentDirectory(const APath: string);
    function GetTempDirectory: string;

    // 测试辅助
    procedure Clear;  // 清空所有文件
  end;

implementation

{ TMemoryFileNode }

constructor TMemoryFileNode.Create(const AName: string; AIsDirectory: Boolean);
begin
  inherited Create;
  Name := AName;
  IsDirectory := AIsDirectory;
  ModificationTime := Now;
  SetLength(Data, 0);
  if AIsDirectory then
    Children := TFPObjectList.Create(True)
  else
    Children := nil;
end;

destructor TMemoryFileNode.Destroy;
begin
  FreeAndNil(Children);
  inherited Destroy;
end;

function TMemoryFileNode.FindChild(const AName: string): TMemoryFileNode;
var
  I: Integer;
  Child: TMemoryFileNode;
begin
  Result := nil;
  if Children = nil then Exit;

  for I := 0 to Children.Count - 1 do
  begin
    Child := TMemoryFileNode(Children[I]);
    if SameText(Child.Name, AName) then
    begin
      Result := Child;
      Exit;
    end;
  end;
end;

procedure TMemoryFileNode.AddChild(ANode: TMemoryFileNode);
begin
  if Children = nil then
    Children := TFPObjectList.Create(True);
  Children.Add(ANode);
end;

procedure TMemoryFileNode.RemoveChild(ANode: TMemoryFileNode);
begin
  if Children <> nil then
    Children.Remove(ANode);
end;

{ TMemoryFileSystem }

constructor TMemoryFileSystem.Create;
begin
  inherited Create;
  FRoot := TMemoryFileNode.Create('', True);
  FCurrentDir := '/';
  FTempDir := '/tmp';
end;

destructor TMemoryFileSystem.Destroy;
begin
  FreeAndNil(FRoot);
  inherited Destroy;
end;

function TMemoryFileSystem.NormalizePath(const APath: string): string;
var
  Parts: TStringList;
  I: Integer;
  S: string;
begin
  // 处理相对路径
  if (Length(APath) = 0) or (APath[1] <> '/') then
    S := FCurrentDir + '/' + APath
  else
    S := APath;

  // 规范化路径
  Parts := TStringList.Create;
  try
    Parts.Delimiter := '/';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := S;

    I := 0;
    while I < Parts.Count do
    begin
      if (Parts[I] = '') or (Parts[I] = '.') then
        Parts.Delete(I)
      else if Parts[I] = '..' then
      begin
        Parts.Delete(I);
        if I > 0 then
        begin
          Dec(I);
          Parts.Delete(I);
        end;
      end
      else
        Inc(I);
    end;

    Result := '/' + Parts.DelimitedText;
    if (Length(Result) > 1) and (Result[Length(Result)] = '/') then
      SetLength(Result, Length(Result) - 1);
  finally
    Parts.Free;
  end;
end;

function TMemoryFileSystem.FindNode(const APath: string; ACreateParents: Boolean): TMemoryFileNode;
var
  NormPath: string;
  Parts: TStringList;
  Current: TMemoryFileNode;
  I: Integer;
  Child: TMemoryFileNode;
begin
  NormPath := NormalizePath(APath);

  if NormPath = '/' then
  begin
    Result := FRoot;
    Exit;
  end;

  Parts := TStringList.Create;
  try
    Parts.Delimiter := '/';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := NormPath;

    Current := FRoot;
    for I := 0 to Parts.Count - 1 do
    begin
      if Parts[I] = '' then Continue;

      Child := Current.FindChild(Parts[I]);
      if Child = nil then
      begin
        if ACreateParents and (I < Parts.Count - 1) then
        begin
          // 创建中间目录
          Child := TMemoryFileNode.Create(Parts[I], True);
          Current.AddChild(Child);
        end
        else
        begin
          Result := nil;
          Exit;
        end;
      end;
      Current := Child;
    end;
    Result := Current;
  finally
    Parts.Free;
  end;
end;

function TMemoryFileSystem.GetParentNode(const APath: string; out ChildName: string): TMemoryFileNode;
var
  NormPath: string;
  LastSlash: Integer;
  ParentPath: string;
begin
  NormPath := NormalizePath(APath);
  LastSlash := Length(NormPath);
  while (LastSlash > 1) and (NormPath[LastSlash] <> '/') do
    Dec(LastSlash);

  if LastSlash <= 1 then
  begin
    ParentPath := '/';
    ChildName := Copy(NormPath, 2, MaxInt);
  end
  else
  begin
    ParentPath := Copy(NormPath, 1, LastSlash - 1);
    ChildName := Copy(NormPath, LastSlash + 1, MaxInt);
  end;

  Result := FindNode(ParentPath, False);
end;

function TMemoryFileSystem.ReadFile(const APath: string): TBytes;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  if (Node = nil) or Node.IsDirectory then
    raise EFileNotFoundException.Create('File not found: ' + APath);
  Result := Copy(Node.Data);
end;

function TMemoryFileSystem.ReadTextFile(const APath: string): string;
var
  Data: TBytes;
begin
  Data := ReadFile(APath);
  SetString(Result, PAnsiChar(@Data[0]), Length(Data));
end;

procedure TMemoryFileSystem.WriteFile(const APath: string; const AData: TBytes);
var
  Parent: TMemoryFileNode;
  ChildName: string;
  Node: TMemoryFileNode;
begin
  Parent := GetParentNode(APath, ChildName);
  if Parent = nil then
    raise EDirectoryNotFoundException.Create('Parent directory not found: ' + APath);

  Node := Parent.FindChild(ChildName);
  if Node = nil then
  begin
    Node := TMemoryFileNode.Create(ChildName, False);
    Parent.AddChild(Node);
  end
  else if Node.IsDirectory then
    raise EFCreateError.Create('Cannot write to directory: ' + APath);

  Node.Data := Copy(AData);
  Node.ModificationTime := Now;
end;

procedure TMemoryFileSystem.WriteTextFile(const APath: string; const AText: string);
var
  Data: TBytes;
begin
  Data := nil;
  SetLength(Data, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Data[0], Length(AText));
  WriteFile(APath, Data);
end;

procedure TMemoryFileSystem.WriteFileAtomic(const APath: string; const AData: TBytes);
begin
  // 内存文件系统中原子写入等同于普通写入
  WriteFile(APath, AData);
end;

procedure TMemoryFileSystem.DeleteFile(const APath: string);
var
  Parent: TMemoryFileNode;
  ChildName: string;
  Node: TMemoryFileNode;
begin
  Parent := GetParentNode(APath, ChildName);
  if Parent = nil then Exit;

  Node := Parent.FindChild(ChildName);
  if (Node <> nil) and not Node.IsDirectory then
    Parent.RemoveChild(Node);
end;

procedure TMemoryFileSystem.CopyFile(const ASrc, ADst: string; AOverwrite: Boolean);
var
  Data: TBytes;
begin
  if (not AOverwrite) and Exists(ADst) then
    raise EFCreateError.Create('File already exists: ' + ADst);
  Data := ReadFile(ASrc);
  WriteFile(ADst, Data);
end;

procedure TMemoryFileSystem.MoveFile(const ASrc, ADst: string; AOverwrite: Boolean);
begin
  CopyFile(ASrc, ADst, AOverwrite);
  DeleteFile(ASrc);
end;

procedure TMemoryFileSystem.CreateDirectory(const APath: string; ARecursive: Boolean);
var
  Parent: TMemoryFileNode;
  ChildName: string;
  Node: TMemoryFileNode;
begin
  if ARecursive then
  begin
    Node := FindNode(APath, True);
    if Node = nil then
    begin
      Parent := GetParentNode(APath, ChildName);
      if Parent <> nil then
      begin
        Node := TMemoryFileNode.Create(ChildName, True);
        Parent.AddChild(Node);
      end;
    end;
  end
  else
  begin
    Parent := GetParentNode(APath, ChildName);
    if Parent = nil then
      raise EDirectoryNotFoundException.Create('Parent directory not found: ' + APath);
    if Parent.FindChild(ChildName) = nil then
    begin
      Node := TMemoryFileNode.Create(ChildName, True);
      Parent.AddChild(Node);
    end;
  end;
end;

procedure TMemoryFileSystem.DeleteDirectory(const APath: string; ARecursive: Boolean);
var
  Parent: TMemoryFileNode;
  ChildName: string;
  Node: TMemoryFileNode;
begin
  Parent := GetParentNode(APath, ChildName);
  if Parent = nil then Exit;

  Node := Parent.FindChild(ChildName);
  if Node = nil then Exit;

  if not Node.IsDirectory then
    raise EDirectoryNotFoundException.Create('Not a directory: ' + APath);

  if not ARecursive and (Node.Children <> nil) and (Node.Children.Count > 0) then
    raise EInOutError.Create('Directory not empty: ' + APath);

  Parent.RemoveChild(Node);
end;

function TMemoryFileSystem.ListDirectory(const APath: string): TFsDirEntries;
var
  Node: TMemoryFileNode;
  I: Integer;
  Child: TMemoryFileNode;
begin
  Result := nil;
  Node := FindNode(APath);
  if (Node = nil) or not Node.IsDirectory then Exit;
  if Node.Children = nil then Exit;

  SetLength(Result, Node.Children.Count);
  for I := 0 to Node.Children.Count - 1 do
  begin
    Child := TMemoryFileNode(Node.Children[I]);
    Result[I].Name := Child.Name;
    if Child.IsDirectory then
      Result[I].FileType := ftDirectory
    else
      Result[I].FileType := ftFile;
  end;
end;

function TMemoryFileSystem.Exists(const APath: string): Boolean;
begin
  Result := FindNode(APath) <> nil;
end;

function TMemoryFileSystem.IsFile(const APath: string): Boolean;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  Result := (Node <> nil) and not Node.IsDirectory;
end;

function TMemoryFileSystem.IsDirectory(const APath: string): Boolean;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  Result := (Node <> nil) and Node.IsDirectory;
end;

function TMemoryFileSystem.IsSymlink(const APath: string): Boolean;
begin
  // 内存文件系统不支持符号链接
  if APath = '' then ;
  Result := False;
end;

function TMemoryFileSystem.GetFileInfo(const APath: string): TFsFileInfo;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  if Node = nil then
    raise EFileNotFoundException.Create('File not found: ' + APath);

  Result.Path := NormalizePath(APath);
  Result.Name := Node.Name;
  if Node.IsDirectory then
    Result.FileType := ftDirectory
  else
    Result.FileType := ftFile;
  Result.Size := Length(Node.Data);
  Result.ModificationTime := Node.ModificationTime;
  Result.AccessTime := Node.ModificationTime;
  Result.CreationTime := Node.ModificationTime;
  Result.IsReadOnly := False;
  Result.IsHidden := False;
end;

function TMemoryFileSystem.GetFileSize(const APath: string): Int64;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  if (Node = nil) or Node.IsDirectory then
    raise EFileNotFoundException.Create('File not found: ' + APath);
  Result := Length(Node.Data);
end;

function TMemoryFileSystem.GetModificationTime(const APath: string): TDateTime;
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  if Node = nil then
    raise EFileNotFoundException.Create('File not found: ' + APath);
  Result := Node.ModificationTime;
end;

procedure TMemoryFileSystem.SetModificationTime(const APath: string; ATime: TDateTime);
var
  Node: TMemoryFileNode;
begin
  Node := FindNode(APath);
  if Node = nil then
    raise EFileNotFoundException.Create('File not found: ' + APath);
  Node.ModificationTime := ATime;
end;

function TMemoryFileSystem.GetCurrentDirectory: string;
begin
  Result := FCurrentDir;
end;

procedure TMemoryFileSystem.SetCurrentDirectory(const APath: string);
begin
  if not IsDirectory(APath) then
    raise EDirectoryNotFoundException.Create('Directory not found: ' + APath);
  FCurrentDir := NormalizePath(APath);
end;

function TMemoryFileSystem.GetTempDirectory: string;
begin
  Result := FTempDir;
end;

procedure TMemoryFileSystem.Clear;
begin
  FreeAndNil(FRoot);
  FRoot := TMemoryFileNode.Create('', True);
end;

end.
