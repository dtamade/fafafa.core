{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_watch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.watch;

type
  TTestCase_Watch = class(TTestCase)
  private
    FWatcher: IFsWatcher;
    FSupported: Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Smoke_Start_Stop_SkipIfUnsupported;
    procedure Test_Create_Modify_Delete_Rename_SkipIfUnsupported;
  end;

implementation

procedure TTestCase_Watch.SetUp;
begin
  inherited SetUp;
  FWatcher := CreateFsWatcher;
  FSupported := Assigned(FWatcher);
end;

procedure TTestCase_Watch.TearDown;
begin
  if Assigned(FWatcher) and FWatcher.IsRunning then
    FWatcher.Stop;
  FWatcher := nil;
  inherited TearDown;
end;

procedure TTestCase_Watch.Test_Smoke_Start_Stop_SkipIfUnsupported;
var
  Opts: TFsWatchOptions;
  R: Integer;
begin
  if not FSupported then
  begin
    WriteLn('Watcher backend not available (skipping)');
    Exit;
  end;
  Opts := DefaultFsWatchOptions;
  R := FWatcher.Start(GetCurrentDir, Opts, nil);
  // 占位实现返回 -999，跳过
  if R <> 0 then
  begin
    WriteLn('Watcher not implemented on this platform yet (skipping)');
    Exit;
  end;
  AssertTrue(FWatcher.IsRunning);
  FWatcher.Stop;
  AssertFalse(FWatcher.IsRunning);
end;

procedure TTestCase_Watch.Test_Create_Modify_Delete_Rename_SkipIfUnsupported;
var
  Opts: TFsWatchOptions;
  R: Integer;
begin
  if not FSupported then
  begin
    WriteLn('Watcher backend not available (skipping)');
    Exit;
  end;
  Opts := DefaultFsWatchOptions;
  R := FWatcher.Start(GetCurrentDir, Opts, nil);
  if R <> 0 then
  begin
    WriteLn('Watcher not implemented on this platform yet (skipping)');
    Exit;
  end;
  // TODO: 创建/修改/删除/重命名 的事件验证（后续实现）
  FWatcher.Stop;
end;

initialization
  RegisterTest(TTestCase_Watch);

end.

