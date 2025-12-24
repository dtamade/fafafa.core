unit fafafa.core.fs.tree;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.tree - 目录树操作

  从 highlevel.pas 拆分，包含：
  - FsCopyTreeEx - 复制目录树
  - FsMoveTreeEx - 移动目录树
  - RemoveTreeEx - 删除目录树
  - TCopyTreeWalker - 复制遍历器
  - TRemoveWalker - 删除遍历器
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path,
  fafafa.core.fs.options,
  fafafa.core.fs.directory,
  fafafa.core.fs.walk,
  fafafa.core.fs.fileio;

// 目录树复制
procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions); overload;
procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions; out aResult: TFsTreeResult); overload;

// 目录树移动
procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions); overload;
procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions; out aResult: TFsTreeResult); overload;

// 目录树删除
procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions); overload;
procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions; out aResult: TFsRemoveTreeResult); overload;

implementation

// ============================================================================
// TCopyTreeWalker - 复制目录树遍历器
// ============================================================================

type
  TCopyTreeWalker = class
  public
    SrcRoot, DstRoot: string;
    Overwrite, PreserveTimes, PreservePerms: Boolean;
    FollowSymlinks, CopySymlinksAsLinks: Boolean;
    ErrorPolicy: TFsErrorPolicy;
    // 统计
    FilesCopied, DirsCreated: QWord;
    BytesCopied: QWord;
    Errors: QWord;
    // 已创建目录缓存
    CreatedDirs: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure EnsureParentDirExists(const APath: string);
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
    function OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
  end;

constructor TCopyTreeWalker.Create;
begin
  inherited Create;
  CreatedDirs := TStringList.Create;
  CreatedDirs.Sorted := True;
  CreatedDirs.Duplicates := dupIgnore;
end;

destructor TCopyTreeWalker.Destroy;
begin
  CreatedDirs.Free;
  inherited Destroy;
end;

procedure TCopyTreeWalker.EnsureParentDirExists(const APath: string);
var
  P: string;
begin
  P := ExtractFilePath(APath);
  if P = '' then Exit;
  if CreatedDirs.IndexOf(P) >= 0 then Exit;
  if not DirectoryExists(P) then
    CreateDirectory(P, True);
  CreatedDirs.Add(P);
end;

function TCopyTreeWalker.OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  if aPath = '' then ;
  if aError = 0 then ;
  if aDepth < 0 then ;

  Inc(Errors);
  Result := weaAbort;
  case ErrorPolicy of
    epAbort: Result := weaAbort;
    epSkipSubtree: Result := weaSkipSubtree;
    epContinue: Result := weaContinue;
  end;
end;

function TCopyTreeWalker.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
var
  Rel, OutPath: string;
  CopyOpts: TFsCopyOptions;
  Target: string;
  R: Integer;
begin
  if aDepth < 0 then ;

  Rel := ToRelativePath(aPath, SrcRoot);
  if Rel = '' then Rel := '.';
  OutPath := JoinPath(DstRoot, Rel);

  // 符号链接处理
  if (aStat.Mode and S_IFMT) = S_IFLNK then
  begin
    if CopySymlinksAsLinks and (not FollowSymlinks) then
    begin
      R := fs_readlink_s(aPath, Target);
      if R < 0 then
      begin
        Inc(Errors);
        case ErrorPolicy of
          epAbort: raise EFsError.Create(TFsErrorCode(R), 'readlink failed: ' + aPath, -R);
          epSkipSubtree, epContinue: Exit(True);
        end;
      end
      else
      begin
        EnsureParentDirExists(OutPath);
        R := fs_symlink(Target, OutPath);
        if R < 0 then
        begin
          Inc(Errors);
          case ErrorPolicy of
            epAbort: raise EFsError.Create(TFsErrorCode(R), 'symlink create failed: ' + OutPath, -R);
            epSkipSubtree, epContinue: ;
          end;
        end;
      end;
    end;
    Exit(True);
  end;

  if (aStat.Mode and S_IFMT) = S_IFDIR then
  begin
    if not DirectoryExists(OutPath) then
      CreateDirectory(OutPath, True);
    Inc(DirsCreated);
    Exit(True);
  end
  else
  begin
    EnsureParentDirExists(OutPath);
    CopyOpts.Overwrite := Overwrite;
    CopyOpts.PreserveTimes := PreserveTimes;
    CopyOpts.PreservePerms := PreservePerms;
    try
      FsCopyFileEx(aPath, OutPath, CopyOpts);
      Inc(FilesCopied);
      try
        Inc(BytesCopied, aStat.Size);
      except
      end;
    except
      on E: EFsError do
      begin
        Inc(Errors);
        case ErrorPolicy of
          epAbort: raise;
          epSkipSubtree, epContinue: ;
        end;
      end;
    end;
  end;
  Exit(True);
end;

// ============================================================================
// TRemoveWalker - 删除目录树遍历器
// ============================================================================

type
  TRemoveWalker = class
  public
    Opts: TFsRemoveTreeOptions;
    FilesRemoved: QWord;
    DirsRemoved: QWord;
    Errors: QWord;
    Dirs: TStringList;
    ExternalTargets: TStringList;
    constructor Create(const AOpts: TFsRemoveTreeOptions);
    destructor Destroy; override;
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
    function OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
  end;

constructor TRemoveWalker.Create(const AOpts: TFsRemoveTreeOptions);
begin
  inherited Create;
  Opts := AOpts;
  FilesRemoved := 0;
  DirsRemoved := 0;
  Errors := 0;
  Dirs := TStringList.Create;
  ExternalTargets := TStringList.Create;
  ExternalTargets.Sorted := True;
  ExternalTargets.Duplicates := dupIgnore;
end;

destructor TRemoveWalker.Destroy;
begin
  Dirs.Free;
  ExternalTargets.Free;
  inherited Destroy;
end;

function TRemoveWalker.OnWalkError(const aPath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  if aPath = '' then ;
  if aError = 0 then ;
  if aDepth < 0 then ;

  Inc(Errors);
  Result := weaAbort;
  case Opts.ErrorPolicy of
    epAbort: Result := weaAbort;
    epContinue: Result := weaContinue;
    epSkipSubtree: Result := weaSkipSubtree;
  end;
end;

function TRemoveWalker.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
var
  R: Integer;
  ModeBits: UInt64;
  LSym: TfsStat;
  LinkT: string;
  RealT: string;
begin
  if aDepth < 0 then ;
  ModeBits := aStat.Mode and S_IFMT;
  if ModeBits = S_IFDIR then
  begin
    Dirs.Add(aPath);
    if Opts.FollowSymlinks then
    begin
      if fs_lstat(aPath, LSym) = 0 then
      begin
        if (LSym.Mode and S_IFMT) = S_IFLNK then
        begin
          LinkT := '';
          if fs_readlink_s(aPath, LinkT) >= 0 then
          begin
            if IsAbsolutePath(LinkT) then
              RealT := ResolvePath(LinkT)
            else
              RealT := ResolvePath(JoinPath(ExtractFileDir(aPath), LinkT));
            if RealT <> '' then
              ExternalTargets.Add(RealT);
          end;
        end;
      end;
    end;
    Exit(True);
  end;

  if Opts.FollowSymlinks and ((aStat.Mode and S_IFMT) = S_IFLNK) then
  begin
    LinkT := '';
    if fs_readlink_s(aPath, LinkT) >= 0 then
    begin
      if IsAbsolutePath(LinkT) then
        RealT := ResolvePath(LinkT)
      else
        RealT := ResolvePath(JoinPath(ExtractFileDir(aPath), LinkT));
      if RealT <> '' then
        ExternalTargets.Add(RealT);
    end;
  end;

  R := fs_unlink(aPath);
  if R < 0 then
  begin
    Inc(Errors);
    case Opts.ErrorPolicy of
      epAbort: begin CheckFsResult(R, 'unlink during remove'); Exit(False); end;
      epContinue, epSkipSubtree: ;
    end;
  end
  else Inc(FilesRemoved);
  Result := True;
end;

// ============================================================================
// FsCopyTreeEx
// ============================================================================

procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions);
var
  Dummy: TFsTreeResult;
begin
  Dummy := Default(TFsTreeResult);
  FsCopyTreeEx(aSrcRoot, aDstRoot, aOpts, Dummy);
end;

procedure FsCopyTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsCopyTreeOptions; out aResult: TFsTreeResult);
var
  SrcRoot, DstRoot: string;
  WalkOpts: TFsWalkOptions;
  Walker: TCopyTreeWalker;
begin
  SrcRoot := ResolvePath(aSrcRoot);
  DstRoot := ResolvePath(aDstRoot);

  if not DirectoryExists(SrcRoot) then
    raise EFsError.Create(FS_ERROR_FILE_NOT_FOUND, 'Source root not found', 0);

  if DirectoryExists(DstRoot) then
  begin
    case aOpts.RootBehavior of
      rbError:
        raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Destination root exists', 0);
      rbReplace:
        DeleteDirectory(DstRoot, True);
      rbMerge: ;
    end;
  end;
  if not DirectoryExists(DstRoot) then
    CreateDirectory(DstRoot, True);

  WalkOpts := FsDefaultWalkOptions;
  WalkOpts.FollowSymlinks := aOpts.FollowSymlinks;
  WalkOpts.IncludeFiles := True;
  WalkOpts.IncludeDirs := False;
  WalkOpts.MaxDepth := -1;
  WalkOpts.UseStreaming := True;
  WalkOpts.Sort := False;

  Walker := TCopyTreeWalker.Create;
  try
    Walker.SrcRoot := SrcRoot;
    Walker.DstRoot := DstRoot;
    Walker.Overwrite := aOpts.Overwrite;
    Walker.PreserveTimes := aOpts.PreserveTimes;
    Walker.PreservePerms := aOpts.PreservePerms;
    Walker.FollowSymlinks := aOpts.FollowSymlinks;
    Walker.CopySymlinksAsLinks := aOpts.CopySymlinksAsLinks;
    Walker.ErrorPolicy := aOpts.ErrorPolicy;
    Walker.FilesCopied := 0;
    Walker.DirsCreated := 0;
    Walker.BytesCopied := 0;

    case aOpts.ErrorPolicy of
      epAbort: WalkOpts.OnError := nil;
      epContinue, epSkipSubtree: WalkOpts.OnError := @Walker.OnWalkError;
    end;

    CheckFsResult(WalkDir(SrcRoot, WalkOpts, @Walker.OnEach), 'copy tree walk');
    aResult.FilesCopied := Walker.FilesCopied;
    aResult.DirsCreated := Walker.DirsCreated;
    aResult.BytesCopied := Walker.BytesCopied;
    aResult.Errors := Walker.Errors;
  finally
    Walker.Free;
  end;
end;

// ============================================================================
// FsMoveTreeEx
// ============================================================================

procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions);
var
  Dummy: TFsTreeResult;
begin
  Dummy := Default(TFsTreeResult);
  FsMoveTreeEx(aSrcRoot, aDstRoot, aOpts, Dummy);
end;

procedure FsMoveTreeEx(const aSrcRoot, aDstRoot: string; const aOpts: TFsMoveTreeOptions; out aResult: TFsTreeResult);
var
  CopyOpts: TFsCopyTreeOptions;
  R: Integer;
  SrcRoot, DstRoot: string;
  TmpName: string;
begin
  SrcRoot := ResolvePath(aSrcRoot);
  DstRoot := ResolvePath(aDstRoot);

  if DirectoryExists(DstRoot) then
  begin
    case aOpts.RootBehavior of
      rbError:
        raise EFsError.Create(FS_ERROR_FILE_EXISTS, 'Destination root exists', 0);
      rbReplace:
        begin
          TmpName := DstRoot + '.old_' + IntToStr(GetTickCount64);
          R := fs_rename(DstRoot, TmpName);
          if R = 0 then
          begin
            R := fs_rename(SrcRoot, DstRoot);
            if R = 0 then
            begin
              DeleteDirectory(TmpName, True);
              aResult.FilesCopied := 0;
              aResult.DirsCreated := 0;
              aResult.BytesCopied := 0;
              aResult.Errors := 0;
              Exit;
            end
            else
            begin
              fs_rename(TmpName, DstRoot);
            end;
          end
          else
          begin
            DeleteDirectory(DstRoot, True);
          end;
        end;
      rbMerge: ;
    end;
  end;

  if not DirectoryExists(DstRoot) then
  begin
    R := fs_rename(SrcRoot, DstRoot);
    if R = 0 then
    begin
      aResult.FilesCopied := 0;
      aResult.DirsCreated := 0;
      aResult.BytesCopied := 0;
      aResult.Errors := 0;
      Exit;
    end;
  end;

  CopyOpts.Overwrite := aOpts.Overwrite;
  CopyOpts.PreserveTimes := aOpts.PreserveTimes;
  CopyOpts.PreservePerms := aOpts.PreservePerms;
  CopyOpts.FollowSymlinks := aOpts.FollowSymlinks;
  CopyOpts.RootBehavior := aOpts.RootBehavior;
  CopyOpts.ErrorPolicy := aOpts.ErrorPolicy;
  CopyOpts.CopySymlinksAsLinks := aOpts.CopySymlinksAsLinks;
  FsCopyTreeEx(SrcRoot, DstRoot, CopyOpts, aResult);
  DeleteDirectory(SrcRoot, True);
end;

// ============================================================================
// RemoveTreeEx
// ============================================================================

procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions);
var
  Dummy: TFsRemoveTreeResult;
begin
  Dummy := Default(TFsRemoveTreeResult);
  RemoveTreeEx(aRoot, aOpts, Dummy);
end;

procedure RemoveTreeEx(const aRoot: string; const aOpts: TFsRemoveTreeOptions; out aResult: TFsRemoveTreeResult);
var
  WalkOpts: TFsWalkOptions;
  LErrorPolicy: TFsErrorPolicy;
  Walker: TRemoveWalker;
  I: Integer;
  DP: string;
  SR: Integer;
  S: TfsStat;
  Rm: Integer;
  AbsTarget: string;
  DelOpts: TFsRemoveTreeOptions;
  RDel: TFsRemoveTreeResult;

  function DoUnlinkOrRmdir(const P: string; const Stat: TfsStat): Integer; inline;
  var ModeBits: UInt64;
  begin
    ModeBits := Stat.Mode and S_IFMT;
    if ModeBits = S_IFDIR then Exit(fs_rmdir(P)) else Exit(fs_unlink(P));
  end;
begin
  aResult.FilesRemoved := 0;
  aResult.DirsRemoved := 0;
  aResult.Errors := 0;

  Walker := TRemoveWalker.Create(aOpts);
  try
    WalkOpts := FsDefaultWalkOptions;
    WalkOpts.FollowSymlinks := aOpts.FollowSymlinks;
    WalkOpts.IncludeFiles := True;
    WalkOpts.IncludeDirs := True;
    WalkOpts.MaxDepth := -1;
    WalkOpts.UseStreaming := True;
    WalkOpts.Sort := False;
    WalkOpts.OnError := @Walker.OnWalkError;

    LErrorPolicy := aOpts.ErrorPolicy;

    if not DirectoryExists(ResolvePath(aRoot)) then
    begin
      aResult.FilesRemoved := Walker.FilesRemoved;
      aResult.DirsRemoved := Walker.DirsRemoved;
      aResult.Errors := Walker.Errors;
      Exit;
    end;

    SR := WalkDir(ResolvePath(aRoot), WalkOpts, @Walker.OnEach);
    if SR < 0 then
    begin
      case LErrorPolicy of
        epAbort:
          CheckFsResult(SR, 'remove tree walk');
        epContinue, epSkipSubtree:
          begin
            Inc(Walker.Errors);
            aResult.FilesRemoved := Walker.FilesRemoved;
            aResult.DirsRemoved := Walker.DirsRemoved;
            aResult.Errors := Walker.Errors;
            Exit;
          end;
      end;
    end;

    if Walker.Dirs.Count > 0 then
    begin
      I := Walker.Dirs.Count - 1;
      while I >= 0 do
      begin
        DP := Walker.Dirs[I];

        if aOpts.FollowSymlinks then
        begin
          if fs_lstat(DP, S) = 0 then
          begin
            if (S.Mode and S_IFMT) = S_IFLNK then
            begin
              SR := fs_unlink(DP);
              if SR < 0 then
              begin
                if not IsNotFound(SR) then
                begin
                  Inc(Walker.Errors);
                  case LErrorPolicy of
                    epAbort: CheckFsResult(SR, 'unlink symlink during remove');
                    epContinue, epSkipSubtree: ;
                  end;
                end;
              end
              else
                Inc(Walker.FilesRemoved);
              Dec(I);
              Continue;
            end;
          end;
        end;

        SR := fs_rmdir(DP);
        if SR < 0 then
        begin
          if not IsNotFound(SR) then
          begin
            Inc(Walker.Errors);
            case LErrorPolicy of
              epAbort: CheckFsResult(SR, 'rmdir during remove');
              epContinue, epSkipSubtree: ;
            end;
          end;
        end
        else Inc(Walker.DirsRemoved);
        Dec(I);
      end;
    end;

    if fs_lstat(aRoot, S) = 0 then
    begin
      Rm := DoUnlinkOrRmdir(aRoot, S);
      if Rm < 0 then
      begin
        Inc(Walker.Errors);
        case LErrorPolicy of
          epAbort: CheckFsResult(Rm, 'remove root');
          epContinue, epSkipSubtree: ;
        end;
      end else begin
        if (S.Mode and S_IFMT) = S_IFDIR then Inc(Walker.DirsRemoved) else Inc(Walker.FilesRemoved);
      end;
    end;

    aResult.FilesRemoved := Walker.FilesRemoved;
    aResult.DirsRemoved := Walker.DirsRemoved;
    aResult.Errors := Walker.Errors;
  finally
    if Assigned(Walker.ExternalTargets) then
    begin
      for I := 0 to Walker.ExternalTargets.Count - 1 do
      begin
        AbsTarget := Walker.ExternalTargets[I];
        if fs_lstat(AbsTarget, S) = 0 then
        begin
          if (S.Mode and S_IFMT) = S_IFDIR then
          begin
            try
              DelOpts := FsDefaultRemoveTreeOptions;
              DelOpts.FollowSymlinks := aOpts.FollowSymlinks;
              DelOpts.ErrorPolicy := LErrorPolicy;
              RemoveTreeEx(AbsTarget, DelOpts, RDel);
              if (fs_lstat(AbsTarget, S) = 0) and ((S.Mode and S_IFMT) = S_IFDIR) then
              begin
                try DeleteDirectory(AbsTarget, True); except end;
              end;
              if (fs_lstat(AbsTarget, S) = 0) and ((S.Mode and S_IFMT) = S_IFDIR) then
                CheckFsResult(fs_rmdir(AbsTarget), 'rmdir external target at finalize');
            except
              on E: EFsError do
              begin
                Inc(Walker.Errors);
                case LErrorPolicy of
                  epAbort: raise;
                  epContinue, epSkipSubtree: ;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    Walker.Free;
  end;
end;

end.
