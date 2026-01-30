unit fafafa.core.fs.walkers;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs, fafafa.core.fs.path, fafafa.core.fs.errors;

// 顶层 Walker 类，避免在实现单元内定义局部类的限制
// 仅供高层使用，不对外导出 API

type
  TCopyTreeWalker = class
  public
    SrcRoot, DstRoot: string;
    OptsCopy: TFsCopyOptions;
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean; // of object
  end;

implementation

function TCopyTreeWalker.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
var
  Rel, OutPath: string;
begin
  Rel := ToRelativePath(aPath, SrcRoot);
  if Rel = '' then Rel := '.';
  OutPath := JoinPath(DstRoot, Rel);
  if (aStat.Mode and S_IFMT) = S_IFDIR then
  begin
    if not DirectoryExists(OutPath) then
      CreateDirectory(OutPath, True);
    Exit(True);
  end
  else
  begin
    if not DirectoryExists(ExtractFilePath(OutPath)) then
      CreateDirectory(ExtractFilePath(OutPath), True);
    FsCopyFileEx(aPath, OutPath, OptsCopy);
    Exit(True);
  end;
end;

end.

