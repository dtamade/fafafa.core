unit fafafa.core.test.utils;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.fs, fafafa.core.fs.path, fafafa.core.args;

// Create a temp directory under system temp path with prefix
function CreateTempDir(const APrefix: string = 'fafafa_test_'): string;

// Create a temp file and return its path (the file is closed immediately)
function CreateTempFile(const APrefix: string = 'fafafa_tmp_'): string;

// Common small helpers for tests
function Arr(const S: array of string): TStringArray;
function Join(const A, B: TStringArray): TStringArray;

implementation

function CreateTempDir(const APrefix: string): string;
var
  Template, Base: string;
begin
  Base := IncludeTrailingPathDelimiter(GetTempDirectory);
  Template := Base + APrefix + 'XXXXXX';
  Result := fs_mkdtemp(Template);
  if Result = '' then
    raise Exception.Create('CreateTempDir failed');
end;

function CreateTempFile(const APrefix: string): string;
var
  Template, Base: string;
  H: TfsFile;
begin
  Base := IncludeTrailingPathDelimiter(GetTempDirectory);
  Template := Base + APrefix + 'XXXXXX';
  H := fs_mkstemp_ex(Template, Result);
  if not IsValidHandle(H) then
    raise Exception.Create('CreateTempFile failed');
  fs_close(H);
end;

function Arr(const S: array of string): TStringArray;
var i: Integer;
begin
  // Initialize managed result to avoid compiler warning
  Result := nil;
  SetLength(Result, Length(S));
  for i := 0 to High(S) do Result[i] := S[i];
end;

function Join(const A, B: TStringArray): TStringArray;
var i, n: Integer;
begin
  // Initialize managed result to avoid compiler warning
  Result := nil;
  n := Length(A) + Length(B);
  SetLength(Result, n);
  for i := 0 to High(A) do Result[i] := A[i];
  for i := 0 to High(B) do Result[Length(A)+i] := B[i];
end;

end.

