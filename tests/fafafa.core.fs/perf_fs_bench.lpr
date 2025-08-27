program perf_fs_bench;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils, Classes, Math,
  fafafa.core.fs;

function NowMs: Int64;
begin
  Result := MilliSecondsBetween(Now, 0);
end;

procedure CheckOk(const Name: string; Code: Integer);
begin
  if Code < 0 then
  begin
    Writeln('ERROR in ', Name, ': ', Code);
    Halt(2);
  end;
end;

procedure BenchSequential(const FilePath: string; FileSizeMB, BlockKB: Integer);
var
  fh: TfsFile;
  buf: Pointer;
  blkSize, totalBytes, written, n, i: Integer;
  t0, t1: Int64;
begin
  blkSize := BlockKB * 1024;
  GetMem(buf, blkSize);
  try
    // fill buffer
    for i := 0 to blkSize - 1 do PByte(buf)[i] := Byte(i and $FF);

    fh := fs_open(FilePath, O_CREAT or O_TRUNC or O_WRONLY, S_IRWXU);
    if fh = INVALID_HANDLE_VALUE then Halt(3);

    totalBytes := FileSizeMB * 1024 * 1024;
    written := 0;

    t0 := NowMs;
    while written < totalBytes do
    begin
      n := fs_write(fh, buf, Min(blkSize, totalBytes - written), -1);
      CheckOk('seq_write', n);
      written += n;
    end;
    fs_close(fh);
    t1 := NowMs;
    if t1 = t0 then t1 := t0 + 1;
    Writeln('Sequential write: ', FileSizeMB:0, ' MB in ', (t1 - t0):0, ' ms, ',
      (FileSizeMB * 1000) div (t1 - t0), ' MB/s');

    // read back sequentially
    fh := fs_open(FilePath, O_RDONLY, 0);
    if fh = INVALID_HANDLE_VALUE then Halt(4);
    written := 0;
    t0 := NowMs;
    while written < totalBytes do
    begin
      n := fs_read(fh, buf, Min(blkSize, totalBytes - written), -1);
      if n <= 0 then Break;
      written += n;
    end;
    fs_close(fh);
    t1 := NowMs;
    if t1 = t0 then t1 := t0 + 1;
    Writeln('Sequential read:  ', FileSizeMB:0, ' MB in ', (t1 - t0):0, ' ms, ',
      (FileSizeMB * 1000) div (t1 - t0), ' MB/s');
  finally
    FreeMem(buf);
  end;
end;

procedure BenchRandomRead(const FilePath: string; FileSizeMB, BlockKB, Samples: Integer);
var
  fh: TfsFile;
  buf: Pointer;
  blkSize, i, n: Integer;
  t0, t1: Int64;
  off: Int64;
begin
  blkSize := BlockKB * 1024;
  GetMem(buf, blkSize);
  try
    fh := fs_open(FilePath, O_RDONLY, 0);
    if fh = INVALID_HANDLE_VALUE then Halt(5);
    Randomize;
    t0 := NowMs;
    for i := 1 to Samples do
    begin
      off := Int64(Random(FileSizeMB * 1024)) * 1024; // align to 1KB
      n := fs_read(fh, buf, blkSize, off);
      CheckOk('rand_read', n);
    end;
    fs_close(fh);
    t1 := NowMs;
    if t1 = t0 then t1 := t0 + 1;
    Writeln('Random read:     ', Samples:0, ' ops in ', (t1 - t0):0, ' ms, ',
      (Samples * 1000) div (t1 - t0), ' ops/s');
  finally
    FreeMem(buf);
  end;
end;

var
  path: string;
  fileMB, seqKB, rndKB, samples: Integer;
begin
  // defaults
  path := 'fs_bench.tmp';
  fileMB := 64;
  seqKB := 128;
  rndKB := 4;
  samples := 5000;

  // parse args: [path] [fileMB] [seqKB] [rndKB] [samples]
  if ParamCount >= 1 then path := ParamStr(1);
  if ParamCount >= 2 then fileMB := StrToIntDef(ParamStr(2), fileMB);
  if ParamCount >= 3 then seqKB := StrToIntDef(ParamStr(3), seqKB);
  if ParamCount >= 4 then rndKB := StrToIntDef(ParamStr(4), rndKB);
  if ParamCount >= 5 then samples := StrToIntDef(ParamStr(5), samples);

  BenchSequential(path, fileMB, seqKB);
  BenchRandomRead(path, fileMB, rndKB, samples);
end.

