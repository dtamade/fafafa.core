program example_fs_path;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$UNITPATH ..\..\src}

uses
  Classes, SysUtils,
  fafafa.core.fs,
  fafafa.core.fs.path;

var
  LTestCount: Integer = 0;
  LPassedCount: Integer = 0;

procedure Log(const aMsg: string; aSuccess: Boolean);
begin
  Inc(LTestCount);
  Write('[');
  if aSuccess then
  begin
    Write(' OK ');
    Inc(LPassedCount);
  end
  else
    Write('FAIL');
  Writeln('] ', aMsg);
end;

procedure LogInfo(const aMsg: string);
begin
  Writeln('[ INFO ] ', aMsg);
end;

procedure TestPathParsing;
var
  LPathInfo: TPathInfo;
begin
  LogInfo('=== Testing Path Parsing ===');
  
  // 测试Windows路径
  {$IFDEF WINDOWS}
  LPathInfo := ParsePath('C:\Users\test\document.txt');
  Log('Parse Windows absolute path', LPathInfo.IsAbsolute and (LPathInfo.FileName = 'document.txt'));
  Log('Extract directory', LPathInfo.Directory = 'C:\Users\test');
  Log('Extract basename', LPathInfo.BaseName = 'document');
  Log('Extract extension', LPathInfo.Extension = '.txt');
  {$ELSE}
  LPathInfo := ParsePath('/home/test/document.txt');
  Log('Parse Unix absolute path', LPathInfo.IsAbsolute and (LPathInfo.FileName = 'document.txt'));
  Log('Extract directory', LPathInfo.Directory = '/home/test');
  Log('Extract basename', LPathInfo.BaseName = 'document');
  Log('Extract extension', LPathInfo.Extension = '.txt');
  {$ENDIF}
  
  // 测试相对路径
  LPathInfo := ParsePath('docs/readme.md');
  Log('Parse relative path', LPathInfo.IsRelative);
  Log('Relative path filename', LPathInfo.FileName = 'readme.md');
  Log('Relative path extension', LPathInfo.Extension = '.md');
end;

procedure TestPathJoining;
var
  LResult: string;
begin
  LogInfo('=== Testing Path Joining ===');
  
  // 测试路径连接
  LResult := JoinPath(['home', 'user', 'documents', 'file.txt']);
  {$IFDEF WINDOWS}
  Log('Join multiple path components', LResult = 'home\user\documents\file.txt');
  {$ELSE}
  Log('Join multiple path components', LResult = 'home/user/documents/file.txt');
  {$ENDIF}
  
  // 测试两个组件连接
  LResult := JoinPath('docs', 'readme.txt');
  {$IFDEF WINDOWS}
  Log('Join two components', LResult = 'docs\readme.txt');
  {$ELSE}
  Log('Join two components', LResult = 'docs/readme.txt');
  {$ENDIF}
  
  // 测试带分隔符的连接
  {$IFDEF WINDOWS}
  LResult := JoinPath('C:\temp\', '\subdir\file.txt');
  Log('Join with separators', Pos('temp\subdir\file.txt', LResult) > 0);
  {$ELSE}
  LResult := JoinPath('/tmp/', '/subdir/file.txt');
  Log('Join with separators', Pos('tmp/subdir/file.txt', LResult) > 0);
  {$ENDIF}
end;

procedure TestPathNormalization;
var
  LResult: string;
begin
  LogInfo('=== Testing Path Normalization ===');
  
  // 测试路径标准化
  {$IFDEF WINDOWS}
  LResult := NormalizePath('C:\temp\..\users\.\documents\file.txt');
  Log('Normalize Windows path with . and ..', LResult = 'C:\users\documents\file.txt');
  
  LResult := NormalizePath('C:\temp\\subdir\\\\file.txt');
  Log('Normalize multiple separators', LResult = 'C:\temp\subdir\file.txt');
  {$ELSE}
  LResult := NormalizePath('/tmp/../home/./user/documents/file.txt');
  Log('Normalize Unix path with . and ..', LResult = '/home/user/documents/file.txt');
  
  LResult := NormalizePath('/tmp//subdir////file.txt');
  Log('Normalize multiple separators', LResult = '/tmp/subdir/file.txt');
  {$ENDIF}
end;

procedure TestPathQueries;
var
  LResult: Boolean;
begin
  LogInfo('=== Testing Path Queries ===');
  
  // 测试绝对路径检测
  {$IFDEF WINDOWS}
  LResult := IsAbsolutePath('C:\Windows\System32');
  Log('Detect Windows absolute path', LResult);
  
  LResult := IsAbsolutePath('relative\path');
  Log('Detect Windows relative path', not LResult);
  {$ELSE}
  LResult := IsAbsolutePath('/usr/bin/ls');
  Log('Detect Unix absolute path', LResult);
  
  LResult := IsAbsolutePath('relative/path');
  Log('Detect Unix relative path', not LResult);
  {$ENDIF}
  
  // 测试相对路径检测
  LResult := IsRelativePath('docs/readme.txt');
  Log('Detect relative path', LResult);
end;

procedure TestPathComponents;
var
  LResult: string;
begin
  LogInfo('=== Testing Path Component Extraction ===');
  
  {$IFDEF WINDOWS}
  LResult := ExtractDirectory('C:\Users\test\document.txt');
  Log('Extract directory from Windows path', LResult = 'C:\Users\test');
  
  LResult := ExtractFileName('C:\Users\test\document.txt');
  Log('Extract filename from Windows path', LResult = 'document.txt');
  
  LResult := ExtractDrive('C:\Users\test\document.txt');
  Log('Extract drive from Windows path', LResult = 'C:');
  {$ELSE}
  LResult := ExtractDirectory('/home/user/document.txt');
  Log('Extract directory from Unix path', LResult = '/home/user');
  
  LResult := ExtractFileName('/home/user/document.txt');
  Log('Extract filename from Unix path', LResult = 'document.txt');
  
  LResult := ExtractDrive('/home/user/document.txt');
  Log('Extract drive from Unix path (should be empty)', LResult = '');
  {$ENDIF}
  
  LResult := ExtractBaseName('document.backup.txt');
  Log('Extract basename with multiple dots', LResult = 'document.backup');
  
  LResult := ExtractFileExtension('archive.tar.gz');
  Log('Extract extension', LResult = '.gz');
end;

procedure TestPathConversion;
var
  LResult: string;
begin
  LogInfo('=== Testing Path Conversion ===');
  
  // 测试路径格式转换
  LResult := ToUnixPath('C:\Windows\System32\file.txt');
  Log('Convert to Unix path format', LResult = 'C:/Windows/System32/file.txt');
  
  LResult := ToWindowsPath('/home/user/documents/file.txt');
  Log('Convert to Windows path format', LResult = '\home\user\documents\file.txt');
  
  // 测试本地路径格式
  {$IFDEF WINDOWS}
  LResult := ToNativePath('/temp/file.txt');
  Log('Convert to native Windows format', LResult = '\temp\file.txt');
  {$ELSE}
  LResult := ToNativePath('C:\temp\file.txt');
  Log('Convert to native Unix format', LResult = 'C:/temp/file.txt');
  {$ENDIF}
end;

procedure TestPathComparison;
var
  LResult: Boolean;
begin
  LogInfo('=== Testing Path Comparison ===');
  
  // 测试路径相等性
  {$IFDEF WINDOWS}
  LResult := PathsEqual('C:\TEMP\FILE.TXT', 'c:\temp\file.txt');
  Log('Windows case-insensitive path comparison', LResult);
  {$ELSE}
  LResult := PathsEqual('/tmp/file.txt', '/tmp/file.txt');
  Log('Unix case-sensitive path comparison', LResult);
  
  LResult := PathsEqual('/tmp/FILE.TXT', '/tmp/file.txt');
  Log('Unix case-sensitive different case', not LResult);
  {$ENDIF}
  
  // 测试子路径检测
  {$IFDEF WINDOWS}
  LResult := IsSubPath('C:\temp\subdir\file.txt', 'C:\temp');
  Log('Detect Windows subpath', LResult);
  {$ELSE}
  LResult := IsSubPath('/tmp/subdir/file.txt', '/tmp');
  Log('Detect Unix subpath', LResult);
  {$ENDIF}
end;

procedure TestPathOperations;
var
  LResult: string;
begin
  LogInfo('=== Testing Path Operations ===');
  
  // 测试扩展名更改
  LResult := ChangeExtension('document.txt', '.pdf');
  Log('Change file extension', LResult = 'document.pdf');
  
  LResult := ChangeExtension('document.txt', 'pdf');
  Log('Change extension without dot', LResult = 'document.pdf');
  
  // 测试路径追加
  {$IFDEF WINDOWS}
  LResult := AppendPath('C:\temp', 'subdir\file.txt');
  Log('Append path components', Pos('temp\subdir\file.txt', LResult) > 0);
  {$ELSE}
  LResult := AppendPath('/tmp', 'subdir/file.txt');
  Log('Append path components', Pos('tmp/subdir/file.txt', LResult) > 0);
  {$ENDIF}
  
  // 测试父路径获取
  {$IFDEF WINDOWS}
  LResult := GetParentPath('C:\Users\test\documents\file.txt');
  Log('Get parent path', LResult = 'C:\Users\test\documents');
  {$ELSE}
  LResult := GetParentPath('/home/user/documents/file.txt');
  Log('Get parent path', LResult = '/home/user/documents');
  {$ENDIF}
end;

procedure TestPathValidation;
var
  LResult: Boolean;
begin
  LogInfo('=== Testing Path Validation ===');
  
  // 测试有效路径
  LResult := IsValidPath('documents/file.txt');
  Log('Valid relative path', LResult);
  
  {$IFDEF WINDOWS}
  LResult := IsValidPath('C:\temp\file<invalid>.txt');
  Log('Invalid Windows path with < character', not LResult);
  
  LResult := IsValidFileName('CON');
  Log('Invalid Windows reserved filename', not LResult);
  {$ELSE}
  LResult := IsValidPath('/tmp/file.txt');
  Log('Valid Unix absolute path', LResult);
  
  LResult := IsValidFileName('file/name');
  Log('Invalid Unix filename with /', not LResult);
  {$ENDIF}
  
  // 测试文件名清理
  LResult := SanitizeFileName('file<>name.txt') <> 'file<>name.txt';
  Log('Sanitize filename with invalid characters', LResult);
end;

procedure TestSpecialPaths;
var
  LResult: string;
begin
  LogInfo('=== Testing Special Paths ===');
  
  // 测试特殊目录获取
  LResult := GetCurrentDirectory;
  Log('Get current directory', LResult <> '');
  LogInfo('Current directory: ' + LResult);
  
  LResult := GetTempDirectory;
  Log('Get temp directory', LResult <> '');
  LogInfo('Temp directory: ' + LResult);
  
  LResult := GetHomeDirectory;
  Log('Get home directory', LResult <> '');
  LogInfo('Home directory: ' + LResult);
  
  LResult := GetExecutableDirectory;
  Log('Get executable directory', LResult <> '');
  LogInfo('Executable directory: ' + LResult);
end;

begin
  Writeln('=== fafafa.core.fs.path Test Suite ===');
  Writeln('Testing comprehensive path operations...');
  Writeln('');

  TestPathParsing;
  Writeln('');
  
  TestPathJoining;
  Writeln('');
  
  TestPathNormalization;
  Writeln('');
  
  TestPathQueries;
  Writeln('');
  
  TestPathComponents;
  Writeln('');
  
  TestPathConversion;
  Writeln('');
  
  TestPathComparison;
  Writeln('');
  
  TestPathOperations;
  Writeln('');
  
  TestPathValidation;
  Writeln('');
  
  TestSpecialPaths;
  Writeln('');

  Writeln('=== Path Test Complete ===');
  Writeln('Total tests: ', LTestCount);
  Writeln('Passed tests: ', LPassedCount);
  Writeln('Success rate: ', Format('%.1f%%', [LPassedCount * 100.0 / LTestCount]));
  
  if LPassedCount = LTestCount then
    Writeln('🎉 All path tests passed!')
  else
    Writeln('❌ Some path tests failed!');
    
  Writeln('');
  Writeln('Path operations tested:');
  Writeln('✓ Path parsing and analysis');
  Writeln('✓ Path joining and construction');
  Writeln('✓ Path normalization');
  Writeln('✓ Path type detection');
  Writeln('✓ Component extraction');
  Writeln('✓ Path format conversion');
  Writeln('✓ Path comparison');
  Writeln('✓ Path manipulation');
  Writeln('✓ Path validation and sanitization');
  Writeln('✓ Special directory access');
end.
