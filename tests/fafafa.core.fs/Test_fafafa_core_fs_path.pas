{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_path;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.path;

type
  { TTestCase_Path - 路径 API 跨平台/边界测试 }
  TTestCase_Path = class(TTestCase)
  published
    // Normalize / Resolve
    procedure Test_Normalize_Basic;
    procedure Test_Normalize_DotDot_Backtracking;
    procedure Test_Normalize_TrailingSlash;
    procedure Test_Resolve_Existing;
    procedure Test_Resolve_Relative_NoTouchDisk;

    // ToRelative / IsSubPath
    procedure Test_ToRelative_Basic;
    procedure Test_ToRelative_NoCommonPrefix;
    procedure Test_IsSubPath_Basic;
    procedure Test_IsSubPath_Windows_CaseInsensitive;

    // FindCommonPrefix / PathsEqual
    procedure Test_FindCommonPrefix_Mixed;
    procedure Test_GetCommonPath_None;
    procedure Test_PathsEqual_WindowsCaseInsensitive;
    procedure Test_PathsEqual_MixedSeparators;

    // ResolvePathEx
    procedure Test_ResolveEx_NoTouchDisk_SameAsResolve;
    procedure Test_ResolveEx_TouchDisk_FollowLinks_WhenExists;
    procedure Test_ResolveEx_TouchDisk_NoFollowLinks_WhenExists;
    procedure Test_ResolveEx_TouchDisk_PathNotExists;

  end;

implementation

procedure TTestCase_Path.Test_Normalize_Basic;
var
  LIn, LOut: string;
begin
  // 统一多余分隔符与 . 片段
  LIn := 'a//b/./c';
  LOut := NormalizePath(LIn);
  AssertTrue('Normalize 应去除 // 和 . 片段', Pos('//', LOut) = 0);
  AssertTrue('Normalize 结果包含 c', Pos('c', LOut) > 0);
end;

procedure TTestCase_Path.Test_Normalize_DotDot_Backtracking;
var
  LOut: string;
begin
  {$IFDEF UNIX}
  LOut := NormalizePath('/a/b/../c/./d');
  AssertEquals('/a/c/d', LOut);
  {$ELSE}
  LOut := NormalizePath('C:\a\b\..\c\.\d');
  AssertTrue('Windows Normalize 应消解 .. 和 .', Pos('..', LOut) = 0);
  AssertTrue('Normalize 结果应包含 c'+PathDelim+'d', Pos('c'+PathDelim+'d', LOut) > 0);
  {$ENDIF}
end;

procedure TTestCase_Path.Test_Normalize_TrailingSlash;
var
  LOut: string;
begin
  {$IFDEF UNIX}
  LOut := NormalizePath('/a/b//');
  AssertEquals('/a/b', LOut);
  {$ELSE}
  LOut := NormalizePath('C:\a\\b\\');
  AssertTrue('Windows Normalize 去尾随分隔符', (LOut <> '') and (LOut[Length(LOut)] <> PathDelim));
  {$ENDIF}
end;

procedure TTestCase_Path.Test_Resolve_Relative_NoTouchDisk;
var
  LAbs: string;
begin
  // 不存在的文件也应解析为绝对规范路径（不触磁盘）
  LAbs := ResolvePath('this_file_should_not_exist_12345.tmp');
  AssertTrue('ResolvePath 返回绝对路径', (Length(LAbs) > 0) and (LAbs[1] <> '.'));
end;


procedure TTestCase_Path.Test_Resolve_Existing;
var
  LPath, LAbs: string;
  LFile: Text;
begin
  // 使用当前目录解析相对路径
  LPath := 'tests_resolve.tmp';
  AssignFile(LFile, LPath);
  Rewrite(LFile);
  Close(LFile);

  LAbs := ResolvePath(LPath);
  AssertTrue('ResolvePath 应返回绝对路径', (Length(LAbs) > 0) and (LAbs[1] <> '.'));

  // 清理
  SysUtils.DeleteFile(LPath);
end;

procedure TTestCase_Path.Test_ToRelative_Basic;
var
  LBase, LPath, LRel: string;
begin
  // Windows 与 Unix 下都应能相对化到父层
  {$IFDEF UNIX}
  LBase := '/a/b';
  LPath := '/a/b/c/d';
  {$ELSE}
  LBase := 'C:\a\b';
  LPath := 'C:\a\b\c\d';
  {$ENDIF}
  LRel := ToRelativePath(LPath, LBase);
  AssertTrue('ToRelativePath 应以不以分隔符开头', (LRel <> '') and (LRel[1] <> PathDelim));
end;

procedure TTestCase_Path.Test_ToRelative_NoCommonPrefix;
var
  LBase, LPath, LRel: string;
begin
  {$IFDEF UNIX}
  LBase := '/x/y';
  LPath := '/a/b/c';
  {$ELSE}
  LBase := 'C:\x\y';
  LPath := 'C:\a\b\c';
  {$ENDIF}
  LRel := ToRelativePath(LPath, LBase);
  AssertTrue('当无公共前缀时，相对路径应不以分隔符开头', (LRel <> '') and (LRel[1] <> PathDelim));
end;

procedure TTestCase_Path.Test_GetCommonPath_None;
var
  LCommon: string;
begin
  {$IFDEF UNIX}
  LCommon := GetCommonPath(['/a/b', '/x/y']);
  AssertEquals('/', LCommon);
  {$ELSE}
  LCommon := GetCommonPath(['C:\a\b', 'C:\x\y']);
  AssertTrue('Windows 下无共同前缀时至少应是驱动器根: ' + LCommon, (Length(LCommon) >= 2));
  {$ENDIF}
end;

procedure TTestCase_Path.Test_PathsEqual_MixedSeparators;
begin
  {$IFDEF WINDOWS}
  AssertTrue('Windows 混合分隔符也应相等', PathsEqual('C:\a\b', 'C:/a/b'));
  {$ELSE}
  AssertTrue('Unix 下相同路径不同重复分隔符应被 Normalize 消解', PathsEqual('/a//b', '/a/b'));
  {$ENDIF}
end;

procedure TTestCase_Path.Test_IsSubPath_Windows_CaseInsensitive;
begin
  {$IFDEF WINDOWS}
  AssertTrue('Windows 下 IsSubPath 大小写不敏感', IsSubPath('C:\Root\Base\Sub', 'c:\root\base'));
  {$ENDIF}
end;

procedure TTestCase_Path.Test_IsSubPath_Basic;
var
  LParent, LChild: string;
begin
  {$IFDEF UNIX}
  LParent := '/root/base';
  LChild := '/root/base/sub/dir';
  {$ELSE}
  LParent := 'C:\root\base';
  LChild := 'C:\root\base\sub\dir';
  {$ENDIF}
  AssertTrue('IsSubPath 应判断为子路径', IsSubPath(LChild, LParent));
end;

procedure TTestCase_Path.Test_FindCommonPrefix_Mixed;
var
  LCommon: string;
begin
  {$IFDEF UNIX}
  LCommon := GetCommonPath(['/root/base/one', '/root/base/two']);
  AssertEquals('/root/base', LCommon);
  {$ELSE}
  LCommon := GetCommonPath(['C:\root\base\one', 'C:\root\base\two']);
  AssertTrue('Windows 下公共前缀应非空: ' + LCommon, LCommon <> '');
  {$ENDIF}
end;

procedure TTestCase_Path.Test_PathsEqual_WindowsCaseInsensitive;
begin
  {$IFDEF WINDOWS}
  AssertTrue('Windows 路径比较应大小写不敏感', PathsEqual('C:\Abc\File.TXT', 'c:\abc\file.txt'));
  {$ELSE}
  AssertFalse('Unix 路径比较应大小写敏感', PathsEqual('/tmp/Abc', '/tmp/abc'));
  {$ENDIF}
end;


procedure TTestCase_Path.Test_ResolveEx_NoTouchDisk_SameAsResolve;
var
  P, R1, R2: string;
begin
  P := 'nested\..\path\file.txt';
  R1 := ResolvePath(P);
  R2 := ResolvePathEx(P, {FollowLinks=}True, {TouchDisk=}False);
  AssertTrue('ResolveEx(no-touch) 应与 Resolve 一致', PathsEqual(R1, R2));
end;

procedure TTestCase_Path.Test_ResolveEx_TouchDisk_FollowLinks_WhenExists;
var
  LFile: Text;
  P, R: string;
begin
  // 创建一个真实存在的文件，确保 TouchDisk 可触发 realpath
  P := 'resolve_ex_test_exists.tmp';
  AssignFile(LFile, P); Rewrite(LFile); Close(LFile);
  try
    R := ResolvePathEx(P, {FollowLinks=}True, {TouchDisk=}True);
    AssertTrue('ResolveEx(touch+follow) 应返回绝对路径', (Length(R) > 0) and (R[1] <> '.'));
    // 不强依赖具体格式，仅断言与非 touch 的绝对路径等价
    AssertTrue('与 Resolve 结果应等价', PathsEqual(R, ResolvePath(P)));
  finally
    SysUtils.DeleteFile(P);
  end;
end;

procedure TTestCase_Path.Test_ResolveEx_TouchDisk_NoFollowLinks_WhenExists;
var
  LFile: Text;
  P, R: string;
begin
  P := 'resolve_ex_test_exists2.tmp';
  AssignFile(LFile, P); Rewrite(LFile); Close(LFile);
  try
    R := ResolvePathEx(P, {FollowLinks=}False, {TouchDisk=}True);
    AssertTrue('ResolveEx(touch+no-follow) 也应返回绝对路径', (Length(R) > 0) and (R[1] <> '.'));
    AssertTrue('与 Resolve 结果等价', PathsEqual(R, ResolvePath(P)));
  finally
    SysUtils.DeleteFile(P);
  end;
end;

procedure TTestCase_Path.Test_ResolveEx_TouchDisk_PathNotExists;
var
  P, R: string;
begin
  P := 'this_path_should_not_exist_xyz_123.tmp';
  R := ResolvePathEx(P, {FollowLinks=}True, {TouchDisk=}True);
  // 不存在时应回退到非触盘绝对规范路径
  AssertTrue('不存在时回退绝对规范路径', PathsEqual(R, ResolvePath(P)));
end;

initialization
  RegisterTest(TTestCase_Path);
end.

