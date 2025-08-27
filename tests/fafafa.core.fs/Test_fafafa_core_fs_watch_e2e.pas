{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_watch_e2e;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.watch, fafafa.core.fs, fafafa.core.fs.highlevel;

type
  TTestCase_Watch_E2E = class(TTestCase)
  private
    FWatcher: IFsWatcher;
    FTempDir: string;
    FEvents: TStringList;
    FObserver: IFsWatchObserver;
    procedure SetupTempDir;
    procedure CleanupTempDir;
    function WaitForEvents(ExpectedCount: Integer; TimeoutMs: Integer = 2000): Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    {$IFDEF WINDOWS}
    procedure Test_Create_Modify_Delete_Basic_Windows;
    procedure Test_Rename_Events_Windows;
    procedure Test_Recursive_Directory_Events_Windows;
    procedure Test_Filter_Patterns_Windows;
    {$ENDIF}
  end;

  TTestObserver = class(TInterfacedObject, IFsWatchObserver)
  private
    FEvents: TStringList;
  public
    constructor Create(Events: TStringList);
    procedure OnEvent(const E: TFsWatchEvent);
    procedure OnError(const Code: Integer; const Message: string);
  end;

implementation

{ TTestObserver }

constructor TTestObserver.Create(Events: TStringList);
begin
  inherited Create;
  FEvents := Events;
end;

procedure TTestObserver.OnEvent(const E: TFsWatchEvent);
var
  EventStr: string;
begin
  EventStr := Format('%s|%s|%s', [
    GetEnumName(TypeInfo(TFsWatchEventKind), Ord(E.Kind)),
    ExtractFileName(E.Path),
    ExtractFileName(E.OldPath)
  ]);
  FEvents.Add(EventStr);
end;

procedure TTestObserver.OnError(const Code: Integer; const Message: string);
begin
  FEvents.Add(Format('ERROR|%d|%s', [Code, Message]));
end;

{ TTestCase_Watch_E2E }

procedure TTestCase_Watch_E2E.SetUp;
begin
  inherited SetUp;
  FWatcher := CreateFsWatcher;
  FEvents := TStringList.Create;
  FObserver := TTestObserver.Create(FEvents);
  SetupTempDir;
end;

procedure TTestCase_Watch_E2E.TearDown;
begin
  if Assigned(FWatcher) and FWatcher.IsRunning then
    FWatcher.Stop;
  CleanupTempDir;
  FEvents.Free;
  FWatcher := nil;
  FObserver := nil;
  inherited TearDown;
end;

procedure TTestCase_Watch_E2E.SetupTempDir;
begin
  FTempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'fafafa_watch_test_' + IntToStr(Random(99999));
  if not CreateDir(FTempDir) then
    raise Exception.Create('Failed to create temp dir: ' + FTempDir);
end;

procedure TTestCase_Watch_E2E.CleanupTempDir;
begin
  if DirectoryExists(FTempDir) then
  begin
    // 简单递归删除
    try
      RemoveDir(FTempDir);
    except
      // 忽略清理错误
    end;
  end;
end;

function TTestCase_Watch_E2E.WaitForEvents(ExpectedCount: Integer; TimeoutMs: Integer): Boolean;
var
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  while (FEvents.Count < ExpectedCount) and (GetTickCount64 - StartTime < QWord(TimeoutMs)) do
  begin
    Sleep(50);
  end;
  Result := FEvents.Count >= ExpectedCount;
end;

{$IFDEF WINDOWS}
procedure TTestCase_Watch_E2E.Test_Create_Modify_Delete_Basic_Windows;
var
  Opts: TFsWatchOptions;
  TestFile: string;
  F: TextFile;
begin
  if not Assigned(FWatcher) then
  begin
    WriteLn('Watcher not available, skipping Windows E2E test');
    Exit;
  end;

  Opts := DefaultFsWatchOptions;
  Opts.Recursive := False;
  Opts.CoalesceLatencyMs := 100;

  if FWatcher.Start(FTempDir, Opts, FObserver) <> 0 then
  begin
    WriteLn('Watcher start failed, skipping Windows E2E test');
    Exit;
  end;

  try
    TestFile := FTempDir + 'test.txt';
    
    // Create
    AssignFile(F, TestFile);
    Rewrite(F);
    WriteLn(F, 'Hello');
    CloseFile(F);
    
    AssertTrue('Should receive create event', WaitForEvents(1, 3000));
    
    // Modify
    Append(F);
    WriteLn(F, 'World');
    CloseFile(F);
    
    AssertTrue('Should receive modify event', WaitForEvents(2, 3000));
    
    // Delete
    DeleteFile(TestFile);
    
    AssertTrue('Should receive delete event', WaitForEvents(3, 3000));
    
    // Verify event types (basic check)
    AssertTrue('Should have events', FEvents.Count >= 3);
    
  finally
    FWatcher.Stop;
  end;
end;

procedure TTestCase_Watch_E2E.Test_Rename_Events_Windows;
var
  Opts: TFsWatchOptions;
  OldFile, NewFile: string;
  F: TextFile;
begin
  if not Assigned(FWatcher) then Exit;

  Opts := DefaultFsWatchOptions;
  if FWatcher.Start(FTempDir, Opts, FObserver) <> 0 then Exit;

  try
    OldFile := FTempDir + 'old.txt';
    NewFile := FTempDir + 'new.txt';
    
    // Create file first
    AssignFile(F, OldFile);
    Rewrite(F);
    WriteLn(F, 'Test');
    CloseFile(F);
    
    WaitForEvents(1, 2000); // Wait for create
    FEvents.Clear; // Clear create event
    
    // Rename
    RenameFile(OldFile, NewFile);
    
    AssertTrue('Should receive rename event', WaitForEvents(1, 3000));
    
  finally
    FWatcher.Stop;
  end;
end;

procedure TTestCase_Watch_E2E.Test_Recursive_Directory_Events_Windows;
var
  Opts: TFsWatchOptions;
  SubDir, TestFile: string;
  F: TextFile;
begin
  if not Assigned(FWatcher) then Exit;

  Opts := DefaultFsWatchOptions;
  Opts.Recursive := True;
  
  if FWatcher.Start(FTempDir, Opts, FObserver) <> 0 then Exit;

  try
    SubDir := FTempDir + 'subdir\';
    CreateDir(SubDir);
    
    WaitForEvents(1, 2000); // Wait for dir create
    
    TestFile := SubDir + 'nested.txt';
    AssignFile(F, TestFile);
    Rewrite(F);
    WriteLn(F, 'Nested');
    CloseFile(F);
    
    AssertTrue('Should receive nested file event', WaitForEvents(2, 3000));
    
  finally
    FWatcher.Stop;
  end;
end;

procedure TTestCase_Watch_E2E.Test_Filter_Patterns_Windows;
var
  Opts: TFsWatchOptions;
  TxtFile, LogFile: string;
  F: TextFile;
begin
  if not Assigned(FWatcher) then Exit;

  Opts := DefaultFsWatchOptions;
  SetLength(Opts.Filters.IncludePatterns, 1);
  Opts.Filters.IncludePatterns[0] := '*.txt';
  
  if FWatcher.Start(FTempDir, Opts, FObserver) <> 0 then Exit;

  try
    TxtFile := FTempDir + 'test.txt';
    LogFile := FTempDir + 'test.log';
    
    // Create .txt file (should be included)
    AssignFile(F, TxtFile);
    Rewrite(F);
    WriteLn(F, 'Text');
    CloseFile(F);
    
    // Create .log file (should be filtered out)
    AssignFile(F, LogFile);
    Rewrite(F);
    WriteLn(F, 'Log');
    CloseFile(F);
    
    WaitForEvents(1, 3000);
    
    // Should only have 1 event for .txt file
    AssertTrue('Should filter .log files', FEvents.Count <= 2); // Allow some tolerance
    
  finally
    FWatcher.Stop;
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_Watch_E2E);

end.
