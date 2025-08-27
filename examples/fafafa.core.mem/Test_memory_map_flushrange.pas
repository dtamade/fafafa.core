{$CODEPAGE UTF8}
unit Test_memory_map_flushrange;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry;

type
  TTestCase_MemoryMap_FlushRange = class(TTestCase)
  published
    procedure Test_FileMapping_FlushRange_Partial;
  end;

implementation

uses
  fafafa.core.mem.memoryMap;

procedure TTestCase_MemoryMap_FlushRange.Test_FileMapping_FlushRange_Partial;
var
  filePath: string;
  mmWrite, mmRead: TMemoryMap;
  part: RawByteString;
  ok: Boolean;
  fs: TFileStream;
  buf: array[0..7] of byte;
begin
  filePath := IncludeTrailingPathDelimiter(GetTempDir) + 'mm_fr_' + IntToHex(Random(MaxInt), 8) + '.dat';
  try
    // 预建文件 1KB
    fs := TFileStream.Create(filePath, fmCreate);
    try
      fs.Size := 1024;
    finally
      fs.Free;
    end;

    // 写映射，写入偏移 100 的 8 字节并仅刷新该范围
    mmWrite := TMemoryMap.Create;
    try
      AssertTrue(mmWrite.OpenFile(filePath, mmaReadWrite));
      part := #$01#$23#$45#$67#$89#$AB#$CD#$EF;
      ok := mmWrite.WriteLPBytes(100, part);
      AssertTrue('WriteLPBytes ok', ok);
      ok := mmWrite.FlushRange(100, SizeOf(UInt32) + Length(part));
      AssertTrue('FlushRange ok', ok);
    finally
      mmWrite.Free;
    end;

    // 通过新映射读取并校验
    mmRead := TMemoryMap.Create;
    try
      AssertTrue(mmRead.OpenFile(filePath, mmaRead));
      part := '';
      ok := mmRead.ReadLPBytes(100, part);
      AssertTrue('ReadLPBytes ok', ok);
      AssertEquals('len=8', 8, Length(part));
      // 校验字节值
      buf[0] := $01; buf[1] := $23; buf[2] := $45; buf[3] := $67;
      buf[4] := $89; buf[5] := $AB; buf[6] := $CD; buf[7] := $EF;
      AssertTrue(CompareMem(@part[1], @buf[0], 8));
    finally
      mmRead.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

initialization
  RegisterTest(TTestCase_MemoryMap_FlushRange);

end.

