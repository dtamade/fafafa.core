unit fafafa.core.fs.path.optimized;

{$CODEPAGE UTF8}
{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

type
  // 优化的路径信息结构
  TPathInfoOptimized = record
    Path: string;
    Directory: string;
    FileName: string;
    BaseName: string;
    Extension: string;
    IsAbsolute: Boolean;
    IsRelative: Boolean;
    Exists: Boolean;
    IsValid: Boolean;
  end;

// 优化的路径操作函数
function ParsePathOptimized(const aPath: string): TPathInfoOptimized;
function ValidatePathOptimized(const aPath: string): Boolean;
function SanitizePathOptimized(const aPath: string): string;
function JoinPathOptimized(const aParts: array of string): string; overload;
function JoinPathOptimized(const aPath1, aPath2: string): string; overload;
function NormalizePathOptimized(const aPath: string): string;

// 批量路径操作
procedure BatchValidatePaths(const aPaths: array of string; var aResults: array of Boolean);
procedure BatchNormalizePaths(const aPaths: array of string; var aResults: array of string);

// 路径缓存管理
type
  TPathCache = class
  private
    FValidationCache: TStringList;
    FNormalizationCache: TStringList;
    FMaxCacheSize: Integer;
    
    procedure CleanupCache;
  public
    constructor Create(aMaxCacheSize: Integer = 1000);
    destructor Destroy; override;
    
    function GetCachedValidation(const aPath: string): Boolean;
    procedure CacheValidation(const aPath: string; aIsValid: Boolean);
    
    function GetCachedNormalization(const aPath: string): string;
    procedure CacheNormalization(const aPath, aNormalizedPath: string);
    
    procedure ClearCache;
  end;

var
  GlobalPathCache: TPathCache;

implementation

function ParsePathOptimized(const aPath: string): TPathInfoOptimized;
var
  LI, LLastSep, LLastDot: Integer;
  LChar: Char;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.Path := aPath;
  
  if Length(aPath) = 0 then
    Exit;
  
  // 单次遍历解析所有信息
  LLastSep := 0;
  LLastDot := 0;
  
  for LI := 1 to Length(aPath) do
  begin
    LChar := aPath[LI];
    
    // 检查路径分隔符
    if (LChar = '/') or (LChar = '\') then
      LLastSep := LI;
      
    // 检查扩展名分隔符
    if LChar = '.' then
      LLastDot := LI;
  end;
  
  // 判断是否为绝对路径
  {$IFDEF WINDOWS}
  Result.IsAbsolute := (Length(aPath) >= 2) and 
    (((aPath[2] = ':') and (aPath[1] in ['A'..'Z', 'a'..'z'])) or
     ((aPath[1] = '\') and (aPath[2] = '\')));
  {$ELSE}
  Result.IsAbsolute := (Length(aPath) > 0) and (aPath[1] = '/');
  {$ENDIF}
  Result.IsRelative := not Result.IsAbsolute;
  
  // 提取目录部分
  if LLastSep > 0 then
    Result.Directory := Copy(aPath, 1, LLastSep - 1)
  else
    Result.Directory := '';
  
  // 提取文件名部分
  if LLastSep > 0 then
    Result.FileName := Copy(aPath, LLastSep + 1, Length(aPath))
  else
    Result.FileName := aPath;
  
  // 提取基础名称和扩展名
  if (LLastDot > LLastSep) and (LLastDot < Length(aPath)) then
  begin
    Result.BaseName := Copy(Result.FileName, 1, LLastDot - LLastSep - 1);
    Result.Extension := Copy(Result.FileName, LLastDot - LLastSep, Length(Result.FileName));
  end
  else
  begin
    Result.BaseName := Result.FileName;
    Result.Extension := '';
  end;
  
  // 验证路径
  Result.IsValid := ValidatePathOptimized(aPath);
  
  // 检查存在性（简化版本）
  Result.Exists := FileExists(aPath) or DirectoryExists(aPath);
end;

function ValidatePathOptimized(const aPath: string): Boolean;
const
  MAX_PATH_LENGTH = 4096;
var
  LI: Integer;
  LChar: Char;
  LFileName: string;
  LUpperFileName: string;
  LPathLen: Integer;
begin
  Result := False;
  LPathLen := Length(aPath);
  
  // 检查路径长度
  if (LPathLen = 0) or (LPathLen > MAX_PATH_LENGTH) then
    Exit;
  
  // 单次遍历进行所有检查
  for LI := 1 to LPathLen do
  begin
    LChar := aPath[LI];
    
    // 检查控制字符 (0-31)
    if Ord(LChar) < 32 then
      Exit;
      
    {$IFDEF WINDOWS}
    // 检查Windows非法字符
    if LChar in ['<', '>', '|', '?', '*', '"'] then
      Exit;
    {$ENDIF}
  end;
  
  // 检查路径遍历攻击（优化版本）
  if (Pos('../', aPath) > 0) or (Pos('..\', aPath) > 0) then
    Exit;
  
  // 检查URL编码攻击
  if (Pos('%2e%2e', LowerCase(aPath)) > 0) or (Pos('..%2f', LowerCase(aPath)) > 0) then
    Exit;
  
  {$IFDEF WINDOWS}
  // 检查Windows保留设备名（优化版本）
  LFileName := ExtractFileName(aPath);
  LUpperFileName := UpperCase(LFileName);
  
  // 基础保留名称
  if (LUpperFileName = 'CON') or (LUpperFileName = 'PRN') or 
     (LUpperFileName = 'AUX') or (LUpperFileName = 'NUL') then
    Exit;
    
  // 带扩展名的保留名称
  if (Pos('CON.', LUpperFileName) = 1) or (Pos('PRN.', LUpperFileName) = 1) or 
     (Pos('AUX.', LUpperFileName) = 1) or (Pos('NUL.', LUpperFileName) = 1) then
    Exit;
    
  // COM和LPT端口（优化检查）
  if (Length(LUpperFileName) >= 4) then
  begin
    if (Copy(LUpperFileName, 1, 3) = 'COM') and 
       (LUpperFileName[4] in ['1'..'9']) and
       ((Length(LUpperFileName) = 4) or (LUpperFileName[5] = '.')) then
      Exit;
      
    if (Copy(LUpperFileName, 1, 3) = 'LPT') and 
       (LUpperFileName[4] in ['1'..'9']) and
       ((Length(LUpperFileName) = 4) or (LUpperFileName[5] = '.')) then
      Exit;
  end;
  {$ENDIF}
  
  Result := True;
end;

function SanitizePathOptimized(const aPath: string): string;
var
  LI, LJ: Integer;
  LChar: Char;
  LLen: Integer;
begin
  LLen := Length(aPath);
  SetLength(Result, LLen);
  LJ := 0;
  
  // 单次遍历进行所有清理操作
  for LI := 1 to LLen do
  begin
    LChar := aPath[LI];
    
    // 跳过控制字符
    if Ord(LChar) < 32 then
      Continue;
      
    // 替换非法字符
    {$IFDEF WINDOWS}
    if LChar in ['<', '>', '|', '?', '*', '"'] then
      LChar := '_';
    {$ENDIF}
    
    Inc(LJ);
    Result[LJ] := LChar;
  end;
  
  SetLength(Result, LJ);
  
  // 去除首尾空格
  Result := Trim(Result);
  
  // 移除路径遍历模式（优化版本）
  while Pos('../', Result) > 0 do
    Delete(Result, Pos('../', Result), 3);
  while Pos('..\', Result) > 0 do
    Delete(Result, Pos('..\', Result), 3);
  
  // 移除URL编码的路径遍历
  while Pos('%2e%2e', LowerCase(Result)) > 0 do
    Delete(Result, Pos('%2e%2e', LowerCase(Result)), 6);
  while Pos('..%2f', LowerCase(Result)) > 0 do
    Delete(Result, Pos('..%2f', LowerCase(Result)), 5);
end;

function JoinPathOptimized(const aParts: array of string): string;
var
  LI: Integer;
  LTotalLen: Integer;
  LCurrentPos: Integer;
  LPart: string;
  LNeedSeparator: Boolean;
begin
  if Length(aParts) = 0 then
  begin
    Result := '';
    Exit;
  end;
  
  // 预计算总长度以避免多次重新分配
  LTotalLen := 0;
  for LI := 0 to High(aParts) do
    Inc(LTotalLen, Length(aParts[LI]) + 1); // +1 for separator
  
  SetLength(Result, LTotalLen);
  LCurrentPos := 1;
  
  for LI := 0 to High(aParts) do
  begin
    LPart := Trim(aParts[LI]);
    if Length(LPart) = 0 then
      Continue;
    
    // 添加分隔符（如果需要）
    LNeedSeparator := (LCurrentPos > 1) and 
      (Result[LCurrentPos - 1] <> '/') and (Result[LCurrentPos - 1] <> '\') and
      (LPart[1] <> '/') and (LPart[1] <> '\');
    
    if LNeedSeparator then
    begin
      Result[LCurrentPos] := DirectorySeparator;
      Inc(LCurrentPos);
    end;
    
    // 复制部分
    Move(LPart[1], Result[LCurrentPos], Length(LPart));
    Inc(LCurrentPos, Length(LPart));
  end;
  
  SetLength(Result, LCurrentPos - 1);
end;

function JoinPathOptimized(const aPath1, aPath2: string): string;
var
  LParts: array[0..1] of string;
begin
  LParts[0] := aPath1;
  LParts[1] := aPath2;
  Result := JoinPathOptimized(LParts);
end;

function NormalizePathOptimized(const aPath: string): string;
var
  LI, LJ: Integer;
  LChar, LPrevChar: Char;
  LLen: Integer;
begin
  LLen := Length(aPath);
  if LLen = 0 then
  begin
    Result := '';
    Exit;
  end;
  
  SetLength(Result, LLen);
  LJ := 0;
  LPrevChar := #0;
  
  // 单次遍历标准化路径
  for LI := 1 to LLen do
  begin
    LChar := aPath[LI];
    
    // 标准化分隔符
    if (LChar = '/') or (LChar = '\') then
      LChar := DirectorySeparator;
    
    // 跳过重复的分隔符
    if (LChar = DirectorySeparator) and (LPrevChar = DirectorySeparator) then
      Continue;
    
    Inc(LJ);
    Result[LJ] := LChar;
    LPrevChar := LChar;
  end;
  
  SetLength(Result, LJ);
  
  // 移除末尾的分隔符（除非是根目录）
  if (Length(Result) > 1) and (Result[Length(Result)] = DirectorySeparator) then
    SetLength(Result, Length(Result) - 1);
end;

procedure BatchValidatePaths(const aPaths: array of string; var aResults: array of Boolean);
var
  LI: Integer;
begin
  if Length(aPaths) <> Length(aResults) then
    raise Exception.Create('Arrays must have same length');
    
  for LI := 0 to High(aPaths) do
    aResults[LI] := ValidatePathOptimized(aPaths[LI]);
end;

procedure BatchNormalizePaths(const aPaths: array of string; var aResults: array of string);
var
  LI: Integer;
begin
  if Length(aPaths) <> Length(aResults) then
    raise Exception.Create('Arrays must have same length');
    
  for LI := 0 to High(aPaths) do
    aResults[LI] := NormalizePathOptimized(aPaths[LI]);
end;

// TPathCache implementation

constructor TPathCache.Create(aMaxCacheSize: Integer);
begin
  inherited Create;
  FMaxCacheSize := aMaxCacheSize;
  FValidationCache := TStringList.Create;
  FValidationCache.Sorted := True;
  FValidationCache.Duplicates := dupIgnore;
  FNormalizationCache := TStringList.Create;
  FNormalizationCache.Sorted := True;
  FNormalizationCache.Duplicates := dupIgnore;
end;

destructor TPathCache.Destroy;
begin
  FValidationCache.Free;
  FNormalizationCache.Free;
  inherited Destroy;
end;

procedure TPathCache.CleanupCache;
begin
  // 简单的LRU清理：删除前一半条目
  while FValidationCache.Count > FMaxCacheSize do
    FValidationCache.Delete(0);
  while FNormalizationCache.Count > FMaxCacheSize do
    FNormalizationCache.Delete(0);
end;

function TPathCache.GetCachedValidation(const aPath: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FValidationCache.IndexOf(aPath);
  if LIndex >= 0 then
    Result := Boolean(PtrInt(FValidationCache.Objects[LIndex]))
  else
    Result := False; // 默认值，表示未缓存
end;

procedure TPathCache.CacheValidation(const aPath: string; aIsValid: Boolean);
begin
  if FValidationCache.Count >= FMaxCacheSize then
    CleanupCache;
  FValidationCache.AddObject(aPath, TObject(PtrInt(aIsValid)));
end;

function TPathCache.GetCachedNormalization(const aPath: string): string;
var
  LIndex: Integer;
begin
  LIndex := FNormalizationCache.IndexOf(aPath);
  if LIndex >= 0 then
    Result := FNormalizationCache.ValueFromIndex[LIndex]
  else
    Result := ''; // 空字符串表示未缓存
end;

procedure TPathCache.CacheNormalization(const aPath, aNormalizedPath: string);
begin
  if FNormalizationCache.Count >= FMaxCacheSize then
    CleanupCache;
  FNormalizationCache.Values[aPath] := aNormalizedPath;
end;

procedure TPathCache.ClearCache;
begin
  FValidationCache.Clear;
  FNormalizationCache.Clear;
end;

initialization
  GlobalPathCache := TPathCache.Create;

finalization
  GlobalPathCache.Free;

end.
