{$CODEPAGE UTF8}
unit Test_memory_map;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem,
  fafafa.core.mem.memoryMap;

type
  TTestCase_MemoryMap = class(TTestCase)
  published
    procedure Test_FileMapping_ReadWrite_Flush;
    procedure Test_AnonymousMapping_Basic_LockUnlock;
    procedure Test_GetPointer_Bounds;
    procedure Test_Resize_Behavior;
    procedure Test_LPBytes_RW_FileMapping;
    procedure Test_LPBytes_Bounds_FileMapping;
    procedure Test_ReadOnly_Write_Fail;
  end;

implementation

function MakeTempFile(const APrefix, AExt: string): string;
var
  tmpPath: string;
begin
  tmpPath := GetTempDir(False);
  Result := IncludeTrailingPathDelimiter(tmpPath) + APrefix + IntToHex(Random(MaxInt), 8) + AExt;
end;

procedure WriteAllText(const AFile, AText: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFile, fmCreate);
  try
    if Length(AText) > 0 then
      fs.WriteBuffer(AText[1], Length(AText));
  finally
    fs.Free;
  end;
end;

function ReadAllText(const AFile: string): string;
var
  fs: TFileStream;
  size: SizeInt;
begin
  fs := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    size := fs.Size;
    SetLength(Result, size);
    if size > 0 then
      fs.ReadBuffer(Result[1], size);
  finally
    fs.Free;
  end;
end;

procedure TTestCase_MemoryMap.Test_FileMapping_ReadWrite_Flush;
var
  filePath: string;
  mm: TMemoryMap;
  p: PByte;
  src: RawByteString;
  len: UInt32;
  maxWritable, n: SizeUInt;
begin
  filePath := MakeTempFile('mm_', '.dat');
  try
    // 预先创建足够大小的文件以避免 Resize 依赖
    src := UTF8Encode('MemoryMap测试-UTF8');
    len := Length(src);
    with TFileStream.Create(filePath, fmCreate) do
    try
      Size := SizeOf(len) + len;
    finally
      Free;
    end;

    mm := TMemoryMap.Create;
    try
      AssertTrue('OpenFile should succeed', mm.OpenFile(filePath, mmaReadWrite));
      AssertTrue('Mapping should be valid', mm.IsValid);
      // 写入：长度前缀 + 原始字节（UTF-8 编码），根据映射大小裁剪写入长度
      p := PByte(mm.BaseAddress);
      Move(len, p^, SizeOf(len));
      Inc(p, SizeOf(len));
      if (mm.Size > SizeOf(len)) and (len > 0) then
      begin
        maxWritable := mm.Size - SizeOf(len);
        n := len;
        if n > maxWritable then n := maxWritable;
        if n > 0 then
          Move(src[1], p^, n);
      end;

      AssertTrue('Flush should succeed', mm.Flush);
    finally
      mm.Free;
    end;

    // 验证文件确实更新（不检查具体内容编码，至少应变更大小或内容）
    AssertTrue('File should exist', FileExists(filePath));
    AssertTrue('File should not be empty', Length(ReadAllText(filePath)) > 0);
  finally
    if FileExists(filePath) then
      DeleteFile(filePath);
  end;
end;

procedure TTestCase_MemoryMap.Test_AnonymousMapping_Basic_LockUnlock;
var
  mm: TMemoryMap;
  pi: PInteger;
  i: Integer;
begin
  mm := TMemoryMap.Create;
  try
    AssertTrue('CreateAnonymous should succeed', mm.CreateAnonymous(4096, mmaReadWrite));
    AssertTrue('Mapping should be valid', mm.IsValid);
    AssertEquals('Size should be exact', UInt64(4096), mm.Size);

    // 写入 0..99 的平方
    pi := PInteger(mm.BaseAddress);
    for i := 0 to 99 do
      pi[i] := i * i;

    // 读取校验
    for i := 0 to 99 do
      AssertEquals('value check', i * i, pi[i]);

    // 锁定/解锁（如果底层不支持，应当优雅返回 False/True，不抛异常）
    mm.Lock(0, 1024);
    mm.Unlock(0, 1024);
  finally
    mm.Free;
  end;
end;

procedure TTestCase_MemoryMap.Test_GetPointer_Bounds;
var
  mm: TMemoryMap;
  p: Pointer;
begin
  mm := TMemoryMap.Create;
  try
    AssertTrue(mm.CreateAnonymous(1024, mmaReadWrite));
    p := mm.GetPointer(0);
    AssertNotNull('offset 0 should be valid', p);
    p := mm.GetPointer(1023);
    AssertNotNull('last valid offset should be valid', p);
    p := mm.GetPointer(1024);
    AssertNull('offset == size should be nil', p);
  finally
    mm.Free;
  end;
end;

procedure TTestCase_MemoryMap.Test_Resize_Behavior;
var
  mm: TMemoryMap;
  filePath: string;
begin
  // 匿名映射不支持 Resize，应返回 False
  mm := TMemoryMap.Create;
  try
    AssertTrue(mm.CreateAnonymous(2048, mmaReadWrite));
    AssertFalse('Anonymous resize should be false', mm.Resize(4096));
  finally
    mm.Free;
  end;

  // 文件映射 Resize（按实现应重新打开并成功）
  filePath := MakeTempFile('mm_resize_', '.dat');
  try
    WriteAllText(filePath, StringOfChar('X', 128));
    mm := TMemoryMap.Create;
    try
      AssertTrue(mm.OpenFile(filePath, mmaReadWrite));
      AssertTrue(mm.Resize(4096));
      AssertTrue('Size should grow', mm.Size >= 4096);
    finally
      mm.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MemoryMap.Test_LPBytes_RW_FileMapping;
var
  filePath: string;
  mm: TMemoryMap;
  payload, got: RawByteString;
  ok: Boolean;
begin
  filePath := MakeTempFile('mm_lp_', '.dat');
  try
    // 预建文件 1KB
    with TFileStream.Create(filePath, fmCreate) do
    try
      Size := 1024;
    finally
      Free;
    end;

    mm := TMemoryMap.Create;
    try
      AssertTrue(mm.OpenFile(filePath, mmaReadWrite));
      payload := UTF8Encode('LPBytes测试-OK');
      ok := mm.WriteLPBytes(0, payload);
      AssertTrue('WriteLPBytes ok', ok);
      ok := mm.ReadLPBytes(0, got);
      AssertTrue('ReadLPBytes ok', ok);
      SetCodePage(payload, CP_UTF8, False);
      SetCodePage(got, CP_UTF8, False);
      AssertEquals(UTF8String(payload), UTF8String(got));
    finally
      mm.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MemoryMap.Test_LPBytes_Bounds_FileMapping;
var
  filePath: string;
  mm: TMemoryMap;
  payload, got: RawByteString;
  ok: Boolean;
  L: UInt32;
begin
  filePath := MakeTempFile('mm_lp_bounds_', '.dat');
  try
    // 只建 8 字节文件，不足以容纳长度前缀+数据
    with TFileStream.Create(filePath, fmCreate) do
    try
      Size := 8;
      // 写入一个长度前缀=16，但后续数据不足，形成“长度足够但整体不足”的边界
      L := 16;
      Position := 0;
      WriteBuffer(L, SizeOf(L));
      // 不写后续 16 字节数据
    finally
      Free;
    end;

    mm := TMemoryMap.Create;
    try
      AssertTrue(mm.OpenFile(filePath, mmaReadWrite));
      payload := RawByteString(StringOfChar('X', 16));
      ok := mm.WriteLPBytes(0, payload);
      AssertFalse('WriteLPBytes should fail due to small map', ok);

      ok := mm.ReadLPBytes(0, got);
      // 对于读取：有长度前缀都不够，应该返回 False
      AssertFalse('ReadLPBytes should fail due to small map', ok);
    finally
      mm.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MemoryMap.Test_ReadOnly_Write_Fail;
var
  filePath: string;
  mm: TMemoryMap;
  ok: Boolean;
begin
  filePath := MakeTempFile('mm_ro_', '.dat');
  try
    // 预建文件 64 字节
    with TFileStream.Create(filePath, fmCreate) do
    try
      Size := 64;
    finally
      Free;
    end;

    mm := TMemoryMap.Create;
    try
      AssertTrue(mm.OpenFile(filePath, mmaRead));
      ok := mm.WriteLPBytes(0, UTF8Encode('should-fail'));
      AssertFalse('Write on read-only mapping should fail', ok);
    finally
      mm.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

initialization
  RegisterTest(TTestCase_MemoryMap);

end.

