{$CODEPAGE UTF8}
program bench_xml_reader_file;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, DateUtils, fafafa.core.xml;

function EnsureBigXmlFile(const FilePath: string; const TargetSizeMB: Integer): string;
var
  FS: TFileStream;
  i, Items, Payload: Integer;
  S: AnsiString;
  Sz: Int64;
begin
  Result := FilePath;
  if FileExists(FilePath) then Exit;

  Items := 20000;
  Payload := 256;
  S := '<?xml version="1.0"?><root>';
  for i := 1 to Items do
    S += '<item id="' + AnsiString(IntToStr(i)) + '">' + StringOfChar('X', Payload) + '</item>';
  S += '</root>';

  FS := TFileStream.Create(FilePath, fmCreate);
  try
    FS.WriteBuffer(S[1], Length(S));
  finally
    FS.Free;
  end;

  Sz := Length(S);
  WriteLn('Generated file: ', FilePath, ', size=', Sz, ' bytes');
end;

procedure BenchReadFile(const FilePath: string);
var
  FS: TFileStream;
  R: IXmlReader;
  T0, T1: QWord;
  ReadItems: Integer = 0;
  Bytes: Int64;
  Secs, MBps: Double;
  BufSize: SizeUInt;
begin
  // 可选环境变量/参数设定缓冲区大小，默认 256KB
  BufSize := 256*1024;
  if GetEnvironmentVariable('XML_BUF_SIZE') <> '' then
    try BufSize := StrToInt64(GetEnvironmentVariable('XML_BUF_SIZE')); except end;

  FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  try
    Bytes := FS.Size;
    T0 := GetTickCount64;
    // 使用流式读取并允许自定义初始缓冲区
    R := CreateXmlReader.ReadFromStream(FS, [xrfIgnoreWhitespace, xrfIgnoreComments], BufSize);
    while R.Read do
      if (R.Token = xtStartElement) and (R.LocalName = 'item') then Inc(ReadItems);
    T1 := GetTickCount64;
  finally
    FS.Free;
  end;
  Secs := (T1 - T0) / 1000.0; if Secs <= 0 then Secs := 0.000001;
  MBps := (Bytes / (1024.0*1024.0)) / Secs;
  WriteLn('ReadFile: items=', ReadItems, ', bytes=', Bytes, ', time(s)=', FormatFloat('0.000', Secs), ', MB/s=', FormatFloat('0.0', MBps), ', buf=', BufSize);
end;

var
  Path: string;
begin
  try
    if ParamCount >= 1 then Path := ParamStr(1)
    else Path := GetEnvironmentVariable('TMP') + PathDelim + 'bench_big.xml';
    EnsureBigXmlFile(Path, 10);
    BenchReadFile(Path);
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

