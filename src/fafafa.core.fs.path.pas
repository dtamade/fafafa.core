unit fafafa.core.fs.path;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, StrUtils, fafafa.core.env;

type
  // 路径类型枚举
  TPathType = (
    ptUnknown,      // 未知类型
    ptFile,         // 文件
    ptDirectory,    // 目录
    ptSymlink,      // 符号链接
    ptDevice,       // 设备文件
    ptPipe,         // 管道
    ptSocket        // 套接字
  );

  // 路径信息记录
  TPathInfo = record
    Path: string;           // 完整路径
    Directory: string;      // 目录部分
    FileName: string;       // 文件名部分
    BaseName: string;       // 基础名称（不含扩展名）
    Extension: string;      // 扩展名
    IsAbsolute: Boolean;    // 是否为绝对路径
    IsRelative: Boolean;    // 是否为相对路径
    PathType: TPathType;    // 路径类型
    Exists: Boolean;        // 是否存在
  end;

// 路径分析和构造
function ParsePath(const aPath: string): TPathInfo;
function JoinPath(const aParts: array of string): string; overload;
function JoinPath(const aDir, aFile: string): string; overload;
function NormalizePath(const aPath: string): string;
function ResolvePath(const aPath: string): string;
// 扩展版本：可控制是否跟随符号链接与是否触盘解析真实路径
function ResolvePathEx(const aPath: string; const aFollowLinks: Boolean; const aTouchDisk: Boolean = False): string;
// 触盘真实路径（等价 Rust canonicalize）：失败时回退为 ResolvePath
function Canonicalize(const aPath: string; const aFollowLinks: Boolean = True): string;

// 路径查询
function IsAbsolutePath(const aPath: string): Boolean;
function IsRelativePath(const aPath: string): Boolean;
function PathExists(const aPath: string): Boolean;
function GetPathType(const aPath: string): TPathType;

// 路径安全验证
function ValidatePath(const aPath: string): Boolean;

// 路径组件提取
function ExtractDirectory(const aPath: string): string;
function ExtractFileName(const aPath: string): string;
function ExtractBaseName(const aPath: string): string;
function ExtractFileExtension(const aPath: string): string;
function ExtractDrive(const aPath: string): string;

// 路径转换
function ToAbsolutePath(const aPath: string): string;
function ToRelativePath(const aPath, aBasePath: string): string;
function ToUnixPath(const aPath: string): string;
function ToWindowsPath(const aPath: string): string;
function ToNativePath(const aPath: string): string;

// 路径比较
function PathsEqual(const aPath1, aPath2: string): Boolean;
function IsSubPath(const aPath, aParentPath: string): Boolean;
function GetCommonPath(const aPaths: array of string): string;

// 路径操作
function ChangeExtension(const aPath, aNewExt: string): string;
function AppendPath(const aBasePath, aSubPath: string): string;
function GetParentPath(const aPath: string): string;
function GetPathDepth(const aPath: string): Integer;

// 特殊路径
function GetCurrentDirectory: string;
function GetTempDirectory: string;
function GetHomeDirectory: string;
function GetExecutableDirectory: string;

// 路径验证
function IsValidPath(const aPath: string): Boolean;
function IsValidFileName(const aFileName: string): Boolean;
function SanitizePath(const aPath: string): string;
function SanitizeFileName(const aFileName: string): string;

// 路径枚举
function EnumeratePathComponents(const aPath: string): TStringList;
function FindCommonPrefix(const aPaths: array of string): string;

implementation

uses
  fafafa.core.fs;

{$IFDEF WINDOWS}
const
  PATH_SEPARATOR = '\';
  ALT_PATH_SEPARATOR = '/';
  // PATH_DELIMITER = ';'; // 未使用，保留注释以备后续解析 PATH 变量时启用
  INVALID_PATH_CHARS: set of Char = ['<', '>', '|', '"', '*', '?'];
  INVALID_FILENAME_CHARS: set of Char = ['<', '>', '|', '"', '*', '?', ':', '\', '/'];
{$ELSE}
const
  PATH_SEPARATOR = '/';
  ALT_PATH_SEPARATOR = '\';
  // PATH_DELIMITER 预留：如需解析 PATH 环境变量可启用
  // PATH_DELIMITER = ':';
  INVALID_PATH_CHARS: set of Char = [#0];
  INVALID_FILENAME_CHARS: set of Char = [#0, '/'];
{$ENDIF}

function ParsePath(const aPath: string): TPathInfo;
var
  LNormalizedPath: string;
begin
  // 显式初始化受管类型字段，避免对包含字符串的记录使用 FillChar 带来的告警
  Result.Path := '';
  Result.Directory := '';
  Result.FileName := '';
  Result.BaseName := '';
  Result.Extension := '';
  Result.IsAbsolute := False;
  Result.IsRelative := False;
  Result.PathType := ptUnknown;
  Result.Exists := False;

  if aPath = '' then
    Exit;

  LNormalizedPath := NormalizePath(aPath);

  Result.Path := LNormalizedPath;
  Result.Directory := ExtractDirectory(LNormalizedPath);
  Result.FileName := ExtractFileName(LNormalizedPath);
  Result.BaseName := ExtractBaseName(LNormalizedPath);
  Result.Extension := ExtractFileExtension(LNormalizedPath);
  Result.IsAbsolute := IsAbsolutePath(LNormalizedPath);
  Result.IsRelative := not Result.IsAbsolute;
  Result.PathType := GetPathType(LNormalizedPath);
  Result.Exists := PathExists(LNormalizedPath);
end;

function JoinPath(const aParts: array of string): string;
var
  I: Integer;
  LPart: string;
begin
  Result := '';

  for I := Low(aParts) to High(aParts) do
  begin
    LPart := Trim(aParts[I]);
    if LPart = '' then
      Continue;

    if Result = '' then
      Result := LPart
    else
    begin
      // 确保路径分隔符正确
      if not (Result[Length(Result)] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) and
         not (LPart[1] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) then
        Result := Result + PATH_SEPARATOR + LPart
      else if (Result[Length(Result)] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) and
              (LPart[1] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) then
        Result := Result + Copy(LPart, 2, Length(LPart) - 1)
      else
        Result := Result + LPart;
    end;
  end;

  Result := NormalizePath(Result);
end;

function JoinPath(const aDir, aFile: string): string;
begin
  Result := JoinPath([aDir, aFile]);
end;

function NormalizePath(const aPath: string): string;
var
  I, J: Integer;
  LParts: array of string;
  LPartCount: Integer;
  LIsAbsolute: Boolean;
  LCurrentPath: string;
  LStartPos, LEndPos: Integer;
begin
  // 显式初始化受管数组，降低编译器保守提示
  LParts := nil;
  if aPath = '' then
  begin
    Result := '';
    Exit;
  end;

  LCurrentPath := StringReplace(aPath, ALT_PATH_SEPARATOR, PATH_SEPARATOR, [rfReplaceAll]);

  // 处理多个连续的路径分隔符
  while Pos(PATH_SEPARATOR + PATH_SEPARATOR, LCurrentPath) > 0 do
    LCurrentPath := StringReplace(LCurrentPath, PATH_SEPARATOR + PATH_SEPARATOR, PATH_SEPARATOR, [rfReplaceAll]);

  LIsAbsolute := IsAbsolutePath(LCurrentPath);

  // 手动分割路径组件
  SetLength(LParts, 0); // 显式初始化，避免受管类型未初始化提示
  SetLength(LParts, 100); // 预分配空间
  LPartCount := 0;
  LStartPos := 1;

  // 跳过开头的分隔符
  if LIsAbsolute and (LCurrentPath[1] = PATH_SEPARATOR) then
    LStartPos := 2;

  for I := LStartPos to Length(LCurrentPath) + 1 do
  begin
    if (I > Length(LCurrentPath)) or (LCurrentPath[I] = PATH_SEPARATOR) then
    begin
      LEndPos := I - 1;
      if LEndPos >= LStartPos then
      begin
        LParts[LPartCount] := Copy(LCurrentPath, LStartPos, LEndPos - LStartPos + 1);
        Inc(LPartCount);
      end;
      LStartPos := I + 1;
    end;
  end;

  // 处理 . 和 .. 组件
  I := 0;
  while I < LPartCount do
  begin
    if LParts[I] = '.' then
    begin
      // 删除当前组件
      for J := I to LPartCount - 2 do
        LParts[J] := LParts[J + 1];
      Dec(LPartCount);
      // 不增加I，因为当前位置现在是下一个组件
      Continue;
    end
    else if LParts[I] = '..' then
    begin
      if (I > 0) and (LParts[I-1] <> '..') then
      begin
        // 删除前一个组件和当前组件
        for J := I - 1 to LPartCount - 3 do
          LParts[J] := LParts[J + 2];
        Dec(LPartCount, 2);
        // 回退到前一个位置，但不能小于0
        if I > 0 then
          Dec(I);
        // 不增加I，因为当前位置现在是下一个组件
        Continue;
      end
      else if LIsAbsolute then
      begin
        // 在绝对路径中删除 ..
        for J := I to LPartCount - 2 do
          LParts[J] := LParts[J + 1];
        Dec(LPartCount);
        // 不增加I，因为当前位置现在是下一个组件
        Continue;
      end;
    end;

    Inc(I);
  end;

  // 重新组装路径
  Result := '';

  for I := 0 to LPartCount - 1 do
  begin
    if I = 0 then
    begin
      if LIsAbsolute then
      begin
        {$IFDEF WINDOWS}
        if (Length(LParts[0]) >= 2) and (LParts[0][2] = ':') then
        begin
          // Windows驱动器路径：C:
          Result := LParts[0];
        end
        else
        begin
          // Windows UNC路径或Unix绝对路径
          Result := PATH_SEPARATOR + LParts[0];
        end;
        {$ELSE}
        // Unix绝对路径
        Result := PATH_SEPARATOR + LParts[0];
        {$ENDIF}
      end
      else
      begin
        // 相对路径
        Result := LParts[0];
      end;
    end
    else
    begin
      // 后续组件
      Result := Result + PATH_SEPARATOR + LParts[I];
    end;
  end;

  // 处理特殊情况
  if LIsAbsolute and (LPartCount = 0) then
  begin
    {$IFDEF WINDOWS}
    Result := 'C:' + PATH_SEPARATOR; // 默认驱动器
    {$ELSE}
    Result := PATH_SEPARATOR; // Unix根目录
    {$ENDIF}
  end;
end;

function ResolvePath(const aPath: string): string;
//var
//  LBuffer: array[0..4095] of Char;
//  LResult: Integer;
begin
  Result := NormalizePath(aPath);

  if not IsAbsolutePath(Result) then
    Result := JoinPath(GetCurrentDirectory, Result);

  // 注意: ResolvePath 只做规范化+绝对化，不触盘
  // 若需要真实路径解析（解析符号链接），请使用:
  //   - ResolvePathEx(aPath, True, True) - 解析符号链接
  //   - Canonicalize(aPath, True) - 解析符号链接的简化版本
end;

function ResolvePathEx(const aPath: string; const aFollowLinks: Boolean; const aTouchDisk: Boolean = False): string;
var
  LNorm: string;
  R: Integer;
  Buf: array[0..4095] of Char;
begin
  // 基线：保持 ResolvePath 语义，不触盘，先做规范化 + 绝对化
  LNorm := ResolvePath(aPath);

  if not aTouchDisk then
  begin
    Result := LNorm;
    Exit;
  end;

  // aTouchDisk = True 时，若存在且允许跟随链接，则尝试真实路径解析
  if PathExists(LNorm) and aFollowLinks then
  begin
    R := fs_realpath(LNorm, @Buf[0], Length(Buf));
    if R >= 0 then
    begin
      SetString(Result, PChar(@Buf[0]), R);
      Exit;
    end;
    // 失败时保持回退，避免破坏调用方
  end;

  // 不存在或未触盘解析时，回退规范绝对路径
  Result := LNorm;
end;

function Canonicalize(const aPath: string; const aFollowLinks: Boolean): string;
var
  LNorm: string;
  R: Integer;
  Buf: array[0..4095] of Char;
begin
  // 先不触盘规范化+绝对化
  LNorm := ResolvePath(aPath);
  // 存在时尝试真实路径
  if PathExists(LNorm) then
  begin
    // 若不跟随链接，退化到规范路径（不触盘），避免不同平台 realpath 差异
    if not aFollowLinks then
    begin
      Result := LNorm;
      Exit;
    end;
    R := fs_realpath(LNorm, @Buf[0], Length(Buf));
    if R >= 0 then
    begin
      SetString(Result, PChar(@Buf[0]), R);
      Exit;
    end;
  end;
  // 不存在或解析失败时，回退为规范绝对路径
  Result := LNorm;
end;


function IsAbsolutePath(const aPath: string): Boolean;
begin
  if aPath = '' then
  begin
    Result := False;
    Exit;
  end;

  {$IFDEF WINDOWS}
  // Windows: C:\ 或 \\server\share 或 \
  Result := ((Length(aPath) >= 3) and (aPath[2] = ':') and (aPath[3] = PATH_SEPARATOR)) or
            ((Length(aPath) >= 2) and (aPath[1] = PATH_SEPARATOR) and (aPath[2] = PATH_SEPARATOR)) or
            ((Length(aPath) >= 1) and (aPath[1] = PATH_SEPARATOR));
  {$ELSE}
  // Unix: /
  Result := (Length(aPath) >= 1) and (aPath[1] = PATH_SEPARATOR);
  {$ENDIF}
end;

function IsRelativePath(const aPath: string): Boolean;
begin
  Result := not IsAbsolutePath(aPath);
end;

function PathExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := fs_stat(aPath, LStat) = 0;
end;

function GetPathType(const aPath: string): TPathType;
var
  LStat: TfsStat;
begin
  Result := ptUnknown;

  if fs_stat(aPath, LStat) <> 0 then
    Exit;

  case LStat.Mode and S_IFMT of
    S_IFREG: Result := ptFile;
    S_IFDIR: Result := ptDirectory;
    S_IFLNK: Result := ptSymlink;
    {$IFDEF UNIX}
    S_IFCHR, S_IFBLK: Result := ptDevice;
    S_IFIFO: Result := ptPipe;
    S_IFSOCK: Result := ptSocket;
    {$ENDIF}
  end;
end;

// 路径组件提取函数实现

function ExtractDirectory(const aPath: string): string;
var
  LPos: Integer;
  LNormalizedPath: string;
begin
  LNormalizedPath := NormalizePath(aPath);
  LPos := Length(LNormalizedPath);

  while (LPos > 0) and not (LNormalizedPath[LPos] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) do
    Dec(LPos);

  if LPos > 0 then
  begin
    {$IFDEF WINDOWS}
    // Windows: 保留驱动器根目录的反斜杠
    if (LPos = 3) and (Length(LNormalizedPath) >= 3) and (LNormalizedPath[2] = ':') then
      Result := Copy(LNormalizedPath, 1, LPos)
    else
      Result := Copy(LNormalizedPath, 1, LPos - 1);
    {$ELSE}
    // Unix: 保留根目录的斜杠
    if LPos = 1 then
      Result := PATH_SEPARATOR
    else
      Result := Copy(LNormalizedPath, 1, LPos - 1);
    {$ENDIF}
  end
  else
    Result := '';
end;

function ExtractFileName(const aPath: string): string;
var
  LPos: Integer;
begin
  LPos := Length(aPath);

  while (LPos > 0) and not (aPath[LPos] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) do
    Dec(LPos);

  Result := Copy(aPath, LPos + 1, Length(aPath) - LPos);
end;

function ExtractBaseName(const aPath: string): string;
var
  LFileName: string;
  LPos: Integer;
begin
  LFileName := ExtractFileName(aPath);
  LPos := LastDelimiter('.', LFileName);

  if (LPos > 1) then
    Result := Copy(LFileName, 1, LPos - 1)
  else
    Result := LFileName;
end;

function ExtractFileExtension(const aPath: string): string;
var
  LFileName: string;
  LPos: Integer;
begin
  LFileName := ExtractFileName(aPath);
  LPos := LastDelimiter('.', LFileName);

  if (LPos > 1) and (LPos < Length(LFileName)) then
    Result := Copy(LFileName, LPos, Length(LFileName) - LPos + 1)
  else
    Result := '';
end;

function ExtractDrive(const aPath: string): string;
begin
  {$IFDEF WINDOWS}
  if (Length(aPath) >= 2) and (aPath[2] = ':') then
    Result := Copy(aPath, 1, 2)
  else
    Result := '';
{$ELSE}
  // Unix 系统没有驱动器概念，但保留参数以保持跨平台接口一致
  if aPath = '' then
    Result := ''
  else
    Result := '';
  {$ENDIF}
end;

// 路径转换函数实现

function ToAbsolutePath(const aPath: string): string;
begin
  if IsAbsolutePath(aPath) then
    Result := NormalizePath(aPath)
  else
    Result := NormalizePath(JoinPath(GetCurrentDirectory, aPath));
end;

function ToRelativePath(const aPath, aBasePath: string): string;
var
  LAbsPath, LAbsBase: string;
  LPathParts, LBaseParts: TStringList;
  LCommonCount, I: Integer;
begin
  LAbsPath := ToAbsolutePath(aPath);
  LAbsBase := ToAbsolutePath(aBasePath);

  if PathsEqual(LAbsPath, LAbsBase) then
  begin
    Result := '.';
    Exit;
  end;

  LPathParts := TStringList.Create;
  LBaseParts := TStringList.Create;
  try
    // 分割路径组件
    LPathParts.Delimiter := PATH_SEPARATOR;
    LPathParts.StrictDelimiter := True;
    LPathParts.DelimitedText := LAbsPath;

    LBaseParts.Delimiter := PATH_SEPARATOR;
    LBaseParts.StrictDelimiter := True;
    LBaseParts.DelimitedText := LAbsBase;

    // 找到公共前缀
    LCommonCount := 0;
    while (LCommonCount < LPathParts.Count) and
          (LCommonCount < LBaseParts.Count) and
          (LPathParts[LCommonCount] = LBaseParts[LCommonCount]) do
      Inc(LCommonCount);

    // 构建相对路径
    Result := '';

    // 添加 .. 来回到公共祖先
    for I := LCommonCount to LBaseParts.Count - 1 do
    begin
      if Result = '' then
        Result := '..'
      else
        Result := Result + PATH_SEPARATOR + '..';
    end;

    // 添加从公共祖先到目标的路径
    for I := LCommonCount to LPathParts.Count - 1 do
    begin
      if Result = '' then
        Result := LPathParts[I]
      else
        Result := Result + PATH_SEPARATOR + LPathParts[I];
    end;

    if Result = '' then
      Result := '.';

  finally
    LPathParts.Free;
    LBaseParts.Free;
  end;
end;

function ToUnixPath(const aPath: string): string;
begin
  Result := StringReplace(aPath, '\', '/', [rfReplaceAll]);
end;

function ToWindowsPath(const aPath: string): string;
begin
  Result := StringReplace(aPath, '/', '\', [rfReplaceAll]);
end;

function ToNativePath(const aPath: string): string;
begin
  {$IFDEF WINDOWS}
  Result := ToWindowsPath(aPath);
  {$ELSE}
  Result := ToUnixPath(aPath);
  {$ENDIF}
end;

// 路径比较函数实现

function PathsEqual(const aPath1, aPath2: string): Boolean;
var
  LPath1, LPath2: string;
begin
  LPath1 := NormalizePath(aPath1);
  LPath2 := NormalizePath(aPath2);

  {$IFDEF WINDOWS}
  // Windows路径不区分大小写
  Result := AnsiCompareText(LPath1, LPath2) = 0;
  {$ELSE}
  // Unix路径区分大小写
  Result := LPath1 = LPath2;
  {$ENDIF}
end;

function IsSubPath(const aPath, aParentPath: string): Boolean;
var
  LPath, LParent: string;
begin
  LPath := NormalizePath(ToAbsolutePath(aPath));
  LParent := NormalizePath(ToAbsolutePath(aParentPath));

  if (LParent <> '') and (LParent[Length(LParent)] <> PATH_SEPARATOR) then
    LParent := LParent + PATH_SEPARATOR;

  {$IFDEF WINDOWS}
  Result := (AnsiCompareText(Copy(LPath + PATH_SEPARATOR, 1, Length(LParent)), LParent) = 0);
  {$ELSE}
  Result := (Copy(LPath + PATH_SEPARATOR, 1, Length(LParent)) = LParent);
  {$ENDIF}
end;

function GetCommonPath(const aPaths: array of string): string;
var
  I, J, LMinLen: Integer;
  LNormalizedPaths: array of string;
  LCommonLen: Integer;
  LAllMatch: Boolean;
begin
  // 显式初始化受管数组，降低编译器保守提示
  LNormalizedPaths := nil;
  Result := '';

  if Length(aPaths) = 0 then
    Exit;

  // 安全初始化，避免受管类型“未初始化”提示（不改变语义）
  SetLength(LNormalizedPaths, Length(aPaths));

  if Length(aPaths) = 1 then
  begin
    Result := ExtractDirectory(NormalizePath(aPaths[0]));
    Exit;
  end;

  // 标准化所有路径
  // SetLength 已提前调用
  LMinLen := MaxInt;

  for I := 0 to High(aPaths) do
  begin
    LNormalizedPaths[I] := NormalizePath(ToAbsolutePath(aPaths[I]));
    if Length(LNormalizedPaths[I]) < LMinLen then
      LMinLen := Length(LNormalizedPaths[I]);
  end;

  // 找到公共前缀
  LCommonLen := 0;
  for J := 1 to LMinLen do
  begin
    LAllMatch := True;
    for I := 1 to High(LNormalizedPaths) do
    begin
      {$IFDEF WINDOWS}
      if AnsiCompareText(LNormalizedPaths[0][J], LNormalizedPaths[I][J]) <> 0 then
      {$ELSE}
      if LNormalizedPaths[0][J] <> LNormalizedPaths[I][J] then
      {$ENDIF}
      begin
        LAllMatch := False;
        Break;
      end;
    end;
    if not LAllMatch then
      Break
    else
      LCommonLen := J;
  end;

  if LCommonLen > 0 then
  begin
    Result := Copy(LNormalizedPaths[0], 1, LCommonLen);
    // 确保在路径分隔符处截断
    while (Length(Result) > 0) and not (Result[Length(Result)] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) do
      SetLength(Result, Length(Result) - 1);

    // 去掉尾随分隔符，标准化为目录路径不以分隔符结尾
    if (Length(Result) > 1) and (Result[Length(Result)] in [PATH_SEPARATOR, ALT_PATH_SEPARATOR]) then
      SetLength(Result, Length(Result) - 1);
  end;
end;

// 路径操作函数实现

function ChangeExtension(const aPath, aNewExt: string): string;
var
  LDir, LBaseName: string;
  LNewExt: string;
begin
  LDir := ExtractDirectory(aPath);
  LBaseName := ExtractBaseName(aPath);

  LNewExt := aNewExt;
  if (LNewExt <> '') and (LNewExt[1] <> '.') then
    LNewExt := '.' + LNewExt;

  if LDir <> '' then
    Result := JoinPath(LDir, LBaseName + LNewExt)
  else
    Result := LBaseName + LNewExt;
end;

function AppendPath(const aBasePath, aSubPath: string): string;
begin
  Result := JoinPath(aBasePath, aSubPath);
end;

function GetParentPath(const aPath: string): string;
begin
  Result := ExtractDirectory(NormalizePath(aPath));
end;

function GetPathDepth(const aPath: string): Integer;
var
  LNormalizedPath: string;
  I: Integer;
begin
  Result := 0;
  LNormalizedPath := NormalizePath(aPath);

  if LNormalizedPath = '' then
    Exit;

  for I := 1 to Length(LNormalizedPath) do
  begin
    if LNormalizedPath[I] = PATH_SEPARATOR then
      Inc(Result);
  end;

  // 如果不是以分隔符结尾，说明还有一个组件
  if (Length(LNormalizedPath) > 0) and (LNormalizedPath[Length(LNormalizedPath)] <> PATH_SEPARATOR) then
    Inc(Result);
end;

// 特殊路径函数实现

function GetCurrentDirectory: string;
begin
  Result := SysUtils.GetCurrentDir;
end;

function GetTempDirectory: string;
begin
  {$IFDEF WINDOWS}
  Result := env_get('TEMP');
  if Result = '' then
    Result := env_get('TMP');
  if Result = '' then
    Result := 'C:\temp';
  {$ELSE}
  Result := env_get('TMPDIR');
  if Result = '' then
    Result := '/tmp';
  {$ENDIF}
end;

function GetHomeDirectory: string;
begin
  {$IFDEF WINDOWS}
  Result := env_get('USERPROFILE');
  if Result = '' then
    Result := env_get('HOMEDRIVE') + env_get('HOMEPATH');
  {$ELSE}
  Result := env_get('HOME');
  {$ENDIF}
end;

function GetExecutableDirectory: string;
begin
  Result := ExtractDirectory(ParamStr(0));
end;

// 路径验证函数实现

function IsValidPath(const aPath: string): Boolean;
var
  I: Integer;
begin
  Result := True;

  if aPath = '' then
  begin
    Result := False;
    Exit;
  end;

  // 检查无效字符
  for I := 1 to Length(aPath) do
  begin
    if aPath[I] in INVALID_PATH_CHARS then
    begin
      Result := False;
      Exit;
    end;
  end;

  {$IFDEF WINDOWS}
  // Windows特殊检查
  if (Length(aPath) > 260) then // MAX_PATH限制
  begin
    Result := False;
    Exit;
  end;
  {$ENDIF}
end;

function IsValidFileName(const aFileName: string): Boolean;
var
  I: Integer;
begin
  Result := True;

  if (aFileName = '') or (aFileName = '.') or (aFileName = '..') then
  begin
    Result := False;
    Exit;
  end;

  // 检查无效字符
  for I := 1 to Length(aFileName) do
  begin
    if aFileName[I] in INVALID_FILENAME_CHARS then
    begin
      Result := False;
      Exit;
    end;
  end;

  {$IFDEF WINDOWS}
  // Windows保留名称检查
  if AnsiCompareText(aFileName, 'CON') = 0 then Result := False
  else if AnsiCompareText(aFileName, 'PRN') = 0 then Result := False
  else if AnsiCompareText(aFileName, 'AUX') = 0 then Result := False
  else if AnsiCompareText(aFileName, 'NUL') = 0 then Result := False
  else if (AnsiCompareText(Copy(aFileName, 1, 3), 'COM') = 0) and (Length(aFileName) = 4) and (aFileName[4] in ['1'..'9']) then Result := False
  else if (AnsiCompareText(Copy(aFileName, 1, 3), 'LPT') = 0) and (Length(aFileName) = 4) and (aFileName[4] in ['1'..'9']) then Result := False;
  {$ENDIF}
end;

function SanitizePath(const aPath: string): string;
var
  I: Integer;
  LChar: Char;
begin
  Result := Trim(aPath);  // 去除首尾空格

  // 移除控制字符 (0-31)
  for I := Length(Result) downto 1 do
  begin
    LChar := Result[I];
    if Ord(LChar) < 32 then
      Delete(Result, I, 1);
  end;

  // 替换无效字符
  for I := 1 to Length(Result) do
  begin
    if Result[I] in INVALID_PATH_CHARS then
      Result[I] := '_';
  end;

  // 移除路径遍历模式
  while Pos('../', Result) > 0 do
    Result := StringReplace(Result, '../', '', [rfReplaceAll]);
  while Pos('..\', Result) > 0 do
    Result := StringReplace(Result, '..\', '', [rfReplaceAll]);

  // 移除URL编码的路径遍历
  Result := StringReplace(Result, '%2e%2e', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '..%2f', '', [rfReplaceAll, rfIgnoreCase]);

  Result := NormalizePath(Result);
end;

function SanitizeFileName(const aFileName: string): string;
var
  I: Integer;
begin
  Result := aFileName;

  if (Result = '.') or (Result = '..') then
  begin
    Result := '_' + Result;
    Exit;
  end;

  // 替换无效字符
  for I := 1 to Length(Result) do
  begin
    if Result[I] in INVALID_FILENAME_CHARS then
      Result[I] := '_';
  end;

  {$IFDEF WINDOWS}
  // 处理Windows保留名称
  if AnsiCompareText(Result, 'CON') = 0 then Result := '_CON'
  else if AnsiCompareText(Result, 'PRN') = 0 then Result := '_PRN'
  else if AnsiCompareText(Result, 'AUX') = 0 then Result := '_AUX'
  else if AnsiCompareText(Result, 'NUL') = 0 then Result := '_NUL'
  else if (AnsiCompareText(Copy(Result, 1, 3), 'COM') = 0) and (Length(Result) = 4) and (Result[4] in ['1'..'9']) then Result := '_' + Result
  else if (AnsiCompareText(Copy(Result, 1, 3), 'LPT') = 0) and (Length(Result) = 4) and (Result[4] in ['1'..'9']) then Result := '_' + Result;
  {$ENDIF}
end;

// 路径枚举函数实现

function EnumeratePathComponents(const aPath: string): TStringList;
var
  LNormalizedPath: string;
begin
  Result := TStringList.Create;

  LNormalizedPath := NormalizePath(aPath);
  if LNormalizedPath = '' then
    Exit;

  Result.Delimiter := PATH_SEPARATOR;
  Result.StrictDelimiter := True;
  Result.DelimitedText := LNormalizedPath;

  // 移除空组件
  while Result.IndexOf('') >= 0 do
    Result.Delete(Result.IndexOf(''));
end;

function FindCommonPrefix(const aPaths: array of string): string;
var
  I, J, LMinLen: Integer;
  LNormalizedPaths: array of string;
begin
  // 显式初始化受管数组，降低编译器保守提示
  LNormalizedPaths := nil;
  Result := '';

  if Length(aPaths) = 0 then
    Exit;

  // 安全初始化，避免受管类型“未初始化”提示（不改变语义）
  SetLength(LNormalizedPaths, Length(aPaths));

  if Length(aPaths) = 1 then
  begin
    Result := aPaths[0];
    Exit;
  end;

  // 标准化所有路径
  // SetLength 已提前调用
  LMinLen := MaxInt;

  for I := 0 to High(aPaths) do
  begin
    LNormalizedPaths[I] := NormalizePath(aPaths[I]);
    if Length(LNormalizedPaths[I]) < LMinLen then
      LMinLen := Length(LNormalizedPaths[I]);
  end;

  // 找到公共前缀
  for J := 1 to LMinLen do
  begin
    for I := 1 to High(LNormalizedPaths) do
    begin
      {$IFDEF WINDOWS}
      if AnsiCompareText(LNormalizedPaths[0][J], LNormalizedPaths[I][J]) <> 0 then
      {$ELSE}
      if LNormalizedPaths[0][J] <> LNormalizedPaths[I][J] then
      {$ENDIF}
        Exit;
    end;
    Result := Result + LNormalizedPaths[0][J];
  end;
end;

{**
 * ValidatePath
 *
 * @desc
 *   验证路径是否安全，防止路径遍历攻击
 *
 * @params
 *   aPath  要验证的路径
 *
 * @return
 *   路径安全返回True，否则返回False
 *}
function ValidatePath(const aPath: string): Boolean;
const
  MAX_PATH_LENGTH = 4096;
var
  I: Integer;
  // LUpperPath 保留以备后续大小写规范检查
  LChar: Char;
  LFileName: string;
begin
  Result := False;

  // 检查路径长度
  if (Length(aPath) = 0) or (Length(aPath) > MAX_PATH_LENGTH) then
    Exit;

  // 检查控制字符 (0-31)
  for I := 1 to Length(aPath) do
  begin
    LChar := aPath[I];
    if Ord(LChar) < 32 then
      Exit;
  end;

  // 检查路径遍历攻击
  if (Pos('../', aPath) > 0) or (Pos('..\', aPath) > 0) or
     (Pos('../', aPath) > 0) or (Pos('..\', aPath) > 0) then
    Exit;

  // 检查URL编码的路径遍历攻击
  if (Pos('%2e%2e', LowerCase(aPath)) > 0) or
     (Pos('%2E%2E', aPath) > 0) or
     (Pos('..%2f', LowerCase(aPath)) > 0) or
     (Pos('..%2F', aPath) > 0) then
    Exit;

  {$IFDEF WINDOWS}
  // 检查Windows非法字符
  for I := 1 to Length(aPath) do
  begin
    LChar := aPath[I];
    if LChar in ['<', '>', '|', '?', '*', '"'] then
      Exit;
  end;

  // 路径长度限制（依配置启用长路径支持时放宽）
  {$IFDEF FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH}
    // 允许 Windows 长路径（理论上上限约为 32767 个宽字符，含终止符）
    if Length(aPath) > 32767 then Exit;
  {$ELSE}
    // 经典 MAX_PATH 限制（260）
    if Length(aPath) > 260 then Exit;
  {$ENDIF}

  // 检查Windows保留设备名
  // LUpperPath := UpperCase(aPath); // 预留：如需对完整路径做额外校验时启用
  LFileName := UpperCase(ExtractFileName(aPath));

  // 基础保留名称
  if (LFileName = 'CON') or (LFileName = 'PRN') or (LFileName = 'AUX') or (LFileName = 'NUL') then
    Exit;

  // 带扩展名的保留名称
  if (Pos('CON.', LFileName) = 1) or (Pos('PRN.', LFileName) = 1) or
     (Pos('AUX.', LFileName) = 1) or (Pos('NUL.', LFileName) = 1) then
    Exit;

  // COM端口 (COM1-COM9)
  for I := 1 to 9 do
  begin
    if (LFileName = 'COM' + IntToStr(I)) or
       (Pos('COM' + IntToStr(I) + '.', LFileName) = 1) then
      Exit;
  end;

  // LPT端口 (LPT1-LPT9)
  for I := 1 to 9 do
  begin
    if (LFileName = 'LPT' + IntToStr(I)) or
       (Pos('LPT' + IntToStr(I) + '.', LFileName) = 1) then
      Exit;
  end;
  {$ENDIF}

  Result := True;
end;



end.
