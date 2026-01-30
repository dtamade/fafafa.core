unit Test_helpers_io;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

function ReadAllText(const APath: string): string;

implementation

function ReadAllText(const APath: string): string;
var
  FS: TFileStream;
  U: UTF8String;
begin
  Result := '';
  if not FileExists(APath) then Exit('');
  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(U, FS.Size);
    if FS.Size > 0 then
      FS.ReadBuffer(U[1], FS.Size);
    Result := string(U);
  finally
    FS.Free;
  end;
end;

end.

