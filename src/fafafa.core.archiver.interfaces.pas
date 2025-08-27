unit fafafa.core.archiver.interfaces;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils;

type
  EArchiverError = class(Exception);

  TArchiveFormat = (
    afTar,
    afZip
  );

  TCompressionAlgorithm = (
    caNone,
    caGZip,
    caDeflate,
    caZstd
  );

  ICompressionProvider = interface
    ['{E2B9656B-97F5-4F21-9C7B-9B8D41E9E1C3}']
    function Algorithm: TCompressionAlgorithm;
    // WrapEncode: 返回一个写入压缩数据的流（包裹 Dest）；调用者负责释放返回的流
    function WrapEncode(const Dest: TStream): TStream;
    // WrapDecode: 返回一个从 Source 读取解压后数据的流；调用者负责释放返回的流
    function WrapDecode(const Source: TStream): TStream;
  end;


  ICompressionProviderEx = interface(ICompressionProvider)
    ['{8C5C8D8F-EE3E-4BF4-A3EE-BA3B3300AAE7}']
    function WrapEncodeWithOptions(const Dest: TStream; const Level: Integer): TStream;
  end;
  IArchiveEntry = interface
    ['{E5F7A6C6-7A30-4B4C-8E8D-4D1E1E3B7E10}']
    function GetName: string;
    function GetSize: Int64;
    function GetModifiedUtc: TDateTime;
    function GetIsDirectory: Boolean;
    property Name: string read GetName;
    property Size: Int64 read GetSize;
    property ModifiedUtc: TDateTime read GetModifiedUtc;
    property IsDirectory: Boolean read GetIsDirectory;
  end;

  IArchiveWriter = interface
    ['{A9C8E3D5-0B7E-4C91-8B1C-0D0B9F7F8E20}']
    procedure AddFile(const FilePath: string; const ArchivePath: string);
    procedure AddDirectory(const ArchivePath: string);
    procedure AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
    procedure Finish; // Flush & finalize archive stream
  end;

  IArchiveReader = interface
    ['{1B7F9F2C-9B2F-4D86-9A5C-6B8E5F2F7B31}']
    function Next(out Entry: IArchiveEntry): Boolean; // iterate entries
    procedure ExtractCurrentToStream(const Dest: TStream);
    procedure SkipCurrent; // skip current entry payload
    procedure Reset; // restart enumeration if supported
  end;

implementation

end.

