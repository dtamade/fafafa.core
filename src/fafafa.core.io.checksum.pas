unit fafafa.core.io.checksum;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.checksum - 校验和计算包装器

  在读写数据的同时计算哈希校验和。默认使用 SHA-256。

  用法:
    var CR: IChecksumReader; Hash: TBytes;
    begin
      CR := IO.Checksum(SomeReader);
      IO.ReadAll(CR);
      Hash := CR.Checksum;  // 获取 SHA-256 校验和
    end;
}

interface

uses
  SysUtils,
  fafafa.core.io.base,
  fafafa.core.crypto.interfaces;

type
  { IChecksumReader - 带校验和计算的读取器接口 }
  IChecksumReader = interface(IReader)
    ['{7D8E5B4C-3A2F-4E9D-B6C5-8A7F6E5D4C3B}']
    function GetChecksum: TBytes;
    procedure Reset;
    property Checksum: TBytes read GetChecksum;
  end;

  { IChecksumWriter - 带校验和计算的写入器接口 }
  IChecksumWriter = interface(IWriter)
    ['{6C7D4A3B-2E1F-4D8C-A5B4-7E6F5D4C3B2A}']
    function GetChecksum: TBytes;
    procedure Reset;
    property Checksum: TBytes read GetChecksum;
  end;

  { TChecksumReader - 带校验和计算的读取器 }
  TChecksumReader = class(TInterfacedObject, IReader, IChecksumReader)
  private
    FInner: IReader;
    FHash: IHashAlgorithm;
  public
    constructor Create(AInner: IReader; AHash: IHashAlgorithm);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    function GetChecksum: TBytes;
    procedure Reset;
  end;

  { TChecksumWriter - 带校验和计算的写入器 }
  TChecksumWriter = class(TInterfacedObject, IWriter, IChecksumWriter)
  private
    FInner: IWriter;
    FHash: IHashAlgorithm;
  public
    constructor Create(AInner: IWriter; AHash: IHashAlgorithm);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    function GetChecksum: TBytes;
    procedure Reset;
  end;

{ 工厂函数 }
function ChecksumReader(AInner: IReader; AHash: IHashAlgorithm): IChecksumReader;
function ChecksumWriter(AInner: IWriter; AHash: IHashAlgorithm): IChecksumWriter;

implementation

{ TChecksumReader }

constructor TChecksumReader.Create(AInner: IReader; AHash: IHashAlgorithm);
begin
  inherited Create;
  FInner := AInner;
  FHash := AHash;
end;

function TChecksumReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Read(Buf, Count);
  if Result > 0 then
    FHash.Update(Buf^, Result);
end;

function TChecksumReader.GetChecksum: TBytes;
begin
  Result := FHash.Finalize;
end;

procedure TChecksumReader.Reset;
begin
  FHash.Reset;
end;

{ TChecksumWriter }

constructor TChecksumWriter.Create(AInner: IWriter; AHash: IHashAlgorithm);
begin
  inherited Create;
  FInner := AInner;
  FHash := AHash;
end;

function TChecksumWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Write(Buf, Count);
  if Result > 0 then
    FHash.Update(Buf^, Result);
end;

function TChecksumWriter.GetChecksum: TBytes;
begin
  Result := FHash.Finalize;
end;

procedure TChecksumWriter.Reset;
begin
  FHash.Reset;
end;

{ 工厂函数 }

function ChecksumReader(AInner: IReader; AHash: IHashAlgorithm): IChecksumReader;
begin
  Result := TChecksumReader.Create(AInner, AHash);
end;

function ChecksumWriter(AInner: IWriter; AHash: IHashAlgorithm): IChecksumWriter;
begin
  Result := TChecksumWriter.Create(AInner, AHash);
end;

end.
