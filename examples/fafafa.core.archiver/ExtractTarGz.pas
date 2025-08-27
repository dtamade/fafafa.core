program ExtractTarGz;
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

procedure EnsureDir(const Path: string);
begin
  if (Path <> '') and not DirectoryExists(Path) then
    if not ForceDirectories(Path) then
      raise Exception.CreateFmt('Failed to create dir: %s', [Path]);
end;

var
  InFile, OutDir: string;
  FS: TFileStream = nil;
  R: IArchiveReader;
  E: IArchiveEntry;
  OutStream: TFileStream = nil;
  TargetPath: string;
begin
  if ParamCount >= 1 then InFile := ParamStr(1) else InFile := 'example.tar.gz';
  if ParamCount >= 2 then OutDir := ParamStr(2) else OutDir := 'out';

  FS := TFileStream.Create(InFile, fmOpenRead or fmShareDenyWrite);
  try
    R := CreateArchiveReader(FS, afTar, caGZip);
    while R.Next(E) do
    begin
      if E.IsDirectory then
      begin
        EnsureDir(IncludeTrailingPathDelimiter(OutDir) + E.Name);
        Continue;
      end;
      EnsureDir(ExtractFileDir(IncludeTrailingPathDelimiter(OutDir) + E.Name));
      TargetPath := IncludeTrailingPathDelimiter(OutDir) + E.Name;
      OutStream := TFileStream.Create(TargetPath, fmCreate or fmShareDenyWrite);
      try
        R.ExtractCurrentToStream(OutStream);
      finally
        OutStream.Free;
      end;
    end;
  finally
    FS.Free;
  end;

  WriteLn('Extracted to: ', OutDir);
end.

