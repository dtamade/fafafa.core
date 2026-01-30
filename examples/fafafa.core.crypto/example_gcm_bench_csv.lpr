program example_gcm_bench_csv;
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.crypto.interfaces,
  fafafa.core.crypto;

procedure AppendCSVLine(const F: TStream; const S: string);
var L: RawByteString;
begin
  L := UTF8Encode(S + #13#10);
  F.WriteBuffer(Pointer(L)^, Length(L));
end;

procedure BenchToCSV(const OutPath: string);
var
  CSV: TFileStream;
  Key, Nonce, AAD, PT, CT: TBytes;
  AEAD: IAEADCipher;
  tagLens: array[0..1] of Integer = (12,16);
  ptLens: array[0..7] of Integer = (0,16,64,256,1024,4096,16384,65536);
  i, j, iter, ItersPerCase: Integer;
  t0, t1: QWord; bytesProc: QWord; dt_ms: Double; mbps: Double;
  line: string;
  dir: string;
begin
  dir := ExtractFilePath(OutPath);
  if (dir <> '') and (not DirectoryExists(dir)) then ForceDirectories(dir);
  CSV := TFileStream.Create(OutPath, fmCreate or fmOpenWrite);
  try
    AppendCSVLine(CSV, 'tag_len,pt_len,iters,bytes,ms,mb_per_s');

    // init fixed inputs
    SetLength(Key, 32); FillChar(Key[0], 32, 7);
    SetLength(Nonce, 12); FillChar(Nonce[0], 12, 9);
    SetLength(AAD, 32); FillChar(AAD[0], 32, 3);

    AEAD := CreateAES256GCM;
    AEAD.SetKey(Key);

    for j := 0 to High(tagLens) do
    begin
      AEAD.SetTagLength(tagLens[j]);
      for i := 0 to High(ptLens) do
      begin
        SetLength(PT, ptLens[i]);
        FillChar(PT[0], Length(PT), 5);
        // warmup
        for iter := 1 to 50 do CT := AEAD.Seal(Nonce, AAD, PT);
        // choose iters proportional to size to keep runtime reasonable
        if Length(PT) <= 16 then ItersPerCase := 5000
        else if Length(PT) <= 256 then ItersPerCase := 3000
        else if Length(PT) <= 4096 then ItersPerCase := 1500
        else ItersPerCase := 200;

        bytesProc := 0; t0 := GetTickCount64;
        for iter := 1 to ItersPerCase do
        begin
          CT := AEAD.Seal(Nonce, AAD, PT);
          Inc(bytesProc, Length(PT));
        end;
        t1 := GetTickCount64;

        dt_ms := (t1 - t0);
        if dt_ms = 0 then dt_ms := 1;
        mbps := (bytesProc / 1024.0 / 1024.0) / (dt_ms / 1000.0);
        line := Format('%d,%d,%d,%d,%.3f,%.4f',[tagLens[j], Length(PT), ItersPerCase, bytesProc, dt_ms, mbps]);
        AppendCSVLine(CSV, line);
      end;
    end;
  finally
    CSV.Free;
  end;
end;

var OutCSV: string;
begin
  Writeln('GCM benchmark -> CSV (UTF-8)…');
  OutCSV := ExtractFilePath(ParamStr(0)) + 'bench_results' + DirectorySeparator + 'gcm_baseline.csv';
  BenchToCSV(OutCSV);
  Writeln('Wrote: ', OutCSV);
end.

