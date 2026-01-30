program walk_example;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.fs.errors,
  fafafa.core.fs, fafafa.core.fs.highlevel;

type
  TWalker = class
  public
    Count: Integer;
    Exts: TStringList;
    constructor Create;
    destructor Destroy; override;
    function VisitCount(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
    function VisitList(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
    function VisitFilter(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
  end;

function IsDir(const AStat: TfsStat): Boolean; inline;
begin
  Result := (AStat.Mode and S_IFMT) = S_IFDIR;
end;

function ShouldFilterOut(const APath: string; const AStat: TfsStat): Boolean;
var
  Base: string;
  LowPath: string;
begin
  if IsDir(AStat) then
  begin
    Base := ExtractFileName(APath);
    Result := (CompareText(Base, '.git') = 0) or (CompareText(Base, 'node_modules') = 0);
    Exit;
  end;
  LowPath := LowerCase(APath);
  Result := (Pos(PathDelim + '.git' + PathDelim, LowPath) > 0) or
            (Pos(PathDelim + 'node_modules' + PathDelim, LowPath) > 0);
end;

constructor TWalker.Create;
begin
  inherited Create;
  Exts := TStringList.Create;
  Exts.CaseSensitive := False;
end;

destructor TWalker.Destroy;
begin
  Exts.Free;
  inherited Destroy;
end;

function TWalker.VisitCount(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // 避免未使用参数提示（常见示例写法，无运行时成本）
  if False and (ADepth = 0) then;
  // 仅计数文件（过滤掉指定目录下的文件）
  if not ShouldFilterOut(APath, AStat) and (not IsDir(AStat)) then
    Inc(Count);
  Result := True;
end;

function TWalker.VisitList(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
var
  I: Integer;
  Indent: string;
begin
  // 使用标记抑制未用参数提示
  if False and (ADepth < 0) then;
  // 过滤掉常见目录（仅影响输出，不影响遍历）
  if ShouldFilterOut(APath, AStat) then
    Exit(True);
  // 按深度缩进打印
  Indent := '';
  for I := 1 to ADepth do Indent := Indent + '  ';
  if IsDir(AStat) then
    WriteLn(Indent, '[D] ', APath)
  else
    WriteLn(Indent, ' -  ', APath);
  Result := True;
end;

function TWalker.VisitFilter(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
var
  Ext: string;
begin
  if False and (ADepth = 0) then;
  // 仅打印特定扩展名的文件，且过滤常见目录
  if not ShouldFilterOut(APath, AStat) and (not IsDir(AStat)) then
  begin
    Ext := LowerCase(ExtractFileExt(APath));
    if (Exts.IndexOf(Ext) >= 0) then
      WriteLn('match: ', APath);
  end;
  Result := True;
end;

procedure Demo(const Root: string);
var
  Opts: TFsWalkOptions;
  W: TWalker;
  Res: Integer;

  // 示例：忽略某些错误类别（权限/非法路径），其他错误则提示
  function ShouldIgnoreError(ARes: Integer): Boolean;
  var K: TFsErrorKind;
  begin
    K := FsErrorKind(ARes);
    Result := (K = fekPermission) or (K = fekInvalid);
  end;

begin
  W := TWalker.Create;
  try
    WriteLn('Root: ', Root);

    // 1) 计数所有文件（忽略权限/非法路径错误）
    Opts := FsDefaultWalkOptions;
    Opts.IncludeDirs := False;
    W.Count := 0;
    Res := WalkDir(Root, Opts, @W.VisitCount);
    if (Res <> 0) and (not ShouldIgnoreError(Res)) then
      WriteLn('WalkDir error (count): ', Res, ' kind=', Ord(FsErrorKind(Res)));
    WriteLn('Files count: ', W.Count);

    // 2) 列出目录（深度 = 1, 仅目录），过滤 .git/node_modules 输出
    WriteLn('--- Directories up to depth 1 (filtered) ---');
    Opts := FsDefaultWalkOptions;
    Opts.IncludeFiles := False;
    Opts.MaxDepth := 1;
    Res := WalkDir(Root, Opts, @W.VisitList);
    if (Res <> 0) and (not ShouldIgnoreError(Res)) then
      WriteLn('WalkDir error (list): ', Res, ' kind=', Ord(FsErrorKind(Res)));

    // 3) 过滤扩展名（仅文件），过滤常见目录
    WriteLn('--- Files with .pas / .inc (filtered) ---');
    Opts := FsDefaultWalkOptions;
    Opts.IncludeDirs := False;
    W.Exts.Clear;
    W.Exts.Add('.pas');
    W.Exts.Add('.inc');
    Res := WalkDir(Root, Opts, @W.VisitFilter);
    if (Res <> 0) and (not ShouldIgnoreError(Res)) then
      WriteLn('WalkDir error (filter): ', Res, ' kind=', Ord(FsErrorKind(Res)));

  finally
    W.Free;
  end;
end;

var
  Root: string;
begin
  if ParamCount >= 1 then
    Root := ParamStr(1)
  else
    Root := GetCurrentDir;
  Demo(Root);
end.

