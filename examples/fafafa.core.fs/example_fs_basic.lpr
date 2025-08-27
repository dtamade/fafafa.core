program example_fs;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch unicodestrings}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$UNITPATH ..\..\src}

uses
  Classes, SysUtils,
  fafafa.core.fs;

const
  TEMP_DIR = 'test_temp';
  TEST_FILE = TEMP_DIR + DirectorySeparator + 'test.txt';
  RENAMED_FILE = TEMP_DIR + DirectorySeparator + 'test_renamed.txt';
  // For lstat test
  {$IFDEF UNIX}
  LINK_FILE = TEMP_DIR + DirectorySeparator + 'test_link';
  {$ENDIF}

procedure Log(const aMsg: string; aSuccess: Boolean);
begin
  Write('[ ');
  if aSuccess then
    Write(' OK ')
  else
    Write('FAIL');
  Writeln(' ] ', aMsg);
  if not aSuccess then
  begin
    Writeln('Test failed. Aborting.');
    Halt(1);
  end;
end;

procedure Cleanup;
begin
  Writeln('--- Running Cleanup ---');
  {$IFDEF UNIX}
  if FileExists(LINK_FILE) then
    fs_unlink(LINK_FILE);
  {$ENDIF}
  if FileExists(RENAMED_FILE) then
    fs_unlink(RENAMED_FILE);
  if FileExists(TEST_FILE) then
    fs_unlink(TEST_FILE);
  if DirectoryExists(TEMP_DIR) then
    fs_rmdir(TEMP_DIR);
  Writeln('Cleanup finished.');
end;

var
  LFile: TfsFile;
  LWriteBuffer, LReadBuffer: TBytes;
  LWriteText, LReadText: string;
  LBytesWritten, LBytesRead: Integer;
  LStat, LLStat: TfsStat;
  LDirEntries: TStringList;
  I: Integer;

begin
  Writeln('--- Starting fafafa.core.fs Test ---');

  Cleanup;
  Writeln('');

  Log('Creating temp directory: ' + TEMP_DIR, fs_mkdir(TEMP_DIR, S_IRWXU) = 0);

  LFile := fs_open(TEST_FILE, O_WRONLY or O_CREAT, S_IRWXU);
  Log('Opening file for writing: ' + TEST_FILE, LFile > 0);

  LWriteText := 'Hello, fafafa.core.fs!';
  LWriteBuffer := TEncoding.UTF8.GetBytes(LWriteText);
  LBytesWritten := fs_write(LFile, @LWriteBuffer[0], Length(LWriteBuffer), -1);
  Log('Writing to file (' + IntToStr(LBytesWritten) + ' bytes)', LBytesWritten = Length(LWriteBuffer));

  Log('Closing file', fs_close(LFile) = 0);

  LFile := fs_open(TEST_FILE, O_RDONLY, 0);
  Log('Opening file for reading: ' + TEST_FILE, LFile > 0);

  SetLength(LReadBuffer, 1024);
  LBytesRead := fs_read(LFile, @LReadBuffer[0], Length(LReadBuffer), 0);
  Log('Reading from file (' + IntToStr(LBytesRead) + ' bytes)', LBytesRead > 0);
  SetLength(LReadBuffer, LBytesRead);
  LReadText := TEncoding.UTF8.GetString(LReadBuffer);
  Log('Verifying file content', LReadText = LWriteText);

  Log('Getting file status via fstat', fs_fstat(LFile, LStat) = 0);
  Log('Verifying file size via fstat (' + IntToStr(LStat.Size) + ' bytes)', LStat.Size = Length(LWriteBuffer));

  Log('Closing file before stat/rename', fs_close(LFile) = 0);

  Log('Getting file status via stat', fs_stat(TEST_FILE, LStat) = 0);
  Log('Verifying file size via stat (' + IntToStr(LStat.Size) + ' bytes)', LStat.Size = Length(LWriteBuffer));

  {$IFDEF UNIX}
  // Test lstat on a symbolic link
  // Note: fpSymlink is in the 'unix' unit
  Log('Creating symbolic link: ' + LINK_FILE, unix.fpSymLink(TEST_FILE, LINK_FILE) = 0);
  Log('Getting link status via lstat', fs_lstat(LINK_FILE, LLStat) = 0);
  Log('Verifying lstat result is a link', (LLStat.Mode and S_IFMT) = S_IFLNK);
  Log('Getting linked file status via stat', fs_stat(LINK_FILE, LStat) = 0);
  Log('Verifying stat result is a regular file', (LStat.Mode and S_IFMT) = S_IFREG);
  {$ENDIF}

  Log('Renaming file to: ' + RENAMED_FILE, fs_rename(TEST_FILE, RENAMED_FILE) = 0);

  LDirEntries := TStringList.Create;
  try
    Log('Scanning directory: ' + TEMP_DIR, fs_scandir(TEMP_DIR, LDirEntries) = 0);
    // On Unix, the link file will also be listed
    {$IFDEF UNIX}
    Log('Verifying scandir result count (expected 2)', LDirEntries.Count = 2);
    {$ELSE}
    Log('Verifying scandir result count (expected 1)', LDirEntries.Count = 1);
    {$ENDIF}
  finally
    LDirEntries.Free;
  end;

  Log('Deleting file: ' + RENAMED_FILE, fs_unlink(RENAMED_FILE) = 0);
  {$IFDEF UNIX}
  Log('Deleting link: ' + LINK_FILE, fs_unlink(LINK_FILE) = 0);
  {$ENDIF}

  Log('Deleting temp directory: ' + TEMP_DIR, fs_rmdir(TEMP_DIR) = 0);

  Writeln('');
  Writeln('--- All fafafa.core.fs Tests Passed Successfully! ---');

  Cleanup;
end.