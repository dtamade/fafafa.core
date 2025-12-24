{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_unified_mode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.errors, fafafa.core.fs.walk, fafafa.core.fs.options;

// 说明：此测试用例聚焦于 WalkDir 在不同低层错误返回模式
// （系统负错误码 vs 统一 TFsErrorCode 负值）下的行为一致性。
// 由于是否启用 FS_UNIFIED_ERRORS 为编译期决定，
// 这里不切换编译开关，仅断言：
// 1) WalkDir 在错误路径下返回的是 TFsErrorCode 负值（统一语义）
// 2) 返回值可被 FsErrorKind 正确分类

type
  TTestCase_UnifiedMode = class(TTestCase)
  published
    procedure Test_WalkDir_InvalidPath_ReturnsUnifiedError;
    procedure Test_WalkDir_PermissionOrInvalid_Categorized;
  end;

implementation

procedure TTestCase_UnifiedMode.Test_WalkDir_InvalidPath_ReturnsUnifiedError;
var
  LOpts: TFsWalkOptions;
  LRes: Integer;
begin
  LOpts := FsDefaultWalkOptions;
  // 使用一个明显无效的路径
  LRes := WalkDir('Z:\this_path_should_not_exist_12345', LOpts, nil);
  if LRes >= 0 then
    Fail('WalkDir should fail on invalid path');
  // 断言为统一的 TFsErrorCode 负值（可被 FsErrorKind 分类）
  // fekInvalid/fekNotFound 之一都可接受，主要确保可分类
  AssertTrue(FsErrorKind(LRes) in [fekInvalid, fekNotFound]);
end;

procedure TTestCase_UnifiedMode.Test_WalkDir_PermissionOrInvalid_Categorized;
var
  LOpts: TFsWalkOptions;
  LRes: Integer;
begin
  LOpts := FsDefaultWalkOptions;
  // Windows 下使用可能受限的系统路径；非 Windows 下相当于无权限目录
  {$IFDEF WINDOWS}
  LRes := WalkDir('C:\System Volume Information', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/root/forbidden_dir_maybe', LOpts, nil);
  {$ENDIF}
  if LRes < 0 then
    AssertTrue(FsErrorKind(LRes) in [fekPermission, fekInvalid, fekNotFound])
  else
    AssertTrue(True); // 在某些环境下可能有权限，视为通过
end;

initialization
  RegisterTest(TTestCase_UnifiedMode);
end.

