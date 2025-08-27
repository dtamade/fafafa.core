{$CODEPAGE UTF8}
program bench_xml_reader;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, DateUtils, fafafa.core.xml;

function MakeBigXml(const Items, PayloadSize: Integer): RawByteString;
var
  i: Integer;
  S: AnsiString;
  Pay: AnsiString;
begin
  SetLength(Pay, PayloadSize);
  if PayloadSize > 0 then FillChar(Pay[1], PayloadSize, Ord('X'));
  S := '<?xml version="1.0"?><root>';
  for i := 1 to Items do
  begin
    S += '<item id="' + AnsiString(IntToStr(i)) + '">' + Pay + '</item>';
  end;
  S += '</root>';
  Result := S;
end;

procedure BenchReadFromStream;
const
  NItems = 20000;       // 可调：2万 * (payload+开销) ~= 10MB 级别
  Payload = 256;        // 每个 item 256 字节
var
  Data: RawByteString;
  MS: TMemoryStream;
  R: IXmlReader;
  T0, T1: QWord;
  ReadItems: Integer = 0;
  Bytes: Int64;
  Secs: Double;
  MBps: Double;
begin
  WriteLn('Generating big XML...');
  Data := MakeBigXml(NItems, Payload);
  Bytes := Length(Data);
  MS := TMemoryStream.Create;
  try
    MS.WriteBuffer(Data[1], Bytes);
    MS.Position := 0;

    T0 := GetTickCount64;
    R := CreateXmlReader.ReadFromStream(MS, [xrfIgnoreWhitespace, xrfIgnoreComments]);
    while R.Read do
      if R.Token = xtStartElement then
        if R.LocalName = 'item' then Inc(ReadItems);
    T1 := GetTickCount64;

    Secs := (T1 - T0) / 1000.0;
    if Secs <= 0 then Secs := 0.000001;
    MBps := (Bytes / (1024.0*1024.0)) / Secs;

    WriteLn('ReadFromStream: items=', ReadItems, ', bytes=', Bytes, ', time(s)=', FormatFloat('0.000', Secs), ', MB/s=', FormatFloat('0.0', MBps));
  finally
    MS.Free;
  end;
end;

procedure BenchReadFromString;
const
  NItems = 20000;
  Payload = 256;
var
  Data: RawByteString;
  R: IXmlReader;
  T0, T1: QWord;
  ReadItems: Integer = 0;
  Bytes: Int64;
  Secs: Double;
  MBps: Double;
begin
  if False then Exit; // 可按需启用对比
  Data := MakeBigXml(NItems, Payload);
  Bytes := Length(Data);
  T0 := GetTickCount64;
  R := CreateXmlReader.ReadFromString(String(Data), [xrfIgnoreWhitespace, xrfIgnoreComments]);
  while R.Read do
    if R.Token = xtStartElement then
      if R.LocalName = 'item' then Inc(ReadItems);
  T1 := GetTickCount64;

  Secs := (T1 - T0) / 1000.0;
  if Secs <= 0 then Secs := 0.000001;
  MBps := (Bytes / (1024.0*1024.0)) / Secs;

  WriteLn('ReadFromString: items=', ReadItems, ', bytes=', Bytes, ', time(s)=', FormatFloat('0.000', Secs), ', MB/s=', FormatFloat('0.0', MBps));
end;

begin
  try
    BenchReadFromStream;
    //BenchReadFromString;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

