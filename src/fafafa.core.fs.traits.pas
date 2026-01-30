unit fafafa.core.fs.traits;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.traits - Rust trait 风格的读写接口

  对标 Rust std::io 的 Read/Write/Seek trait，提供：
  - IFsRead: 读取接口
  - IFsWrite: 写入接口
  - IFsSeek: 定位接口
  - IFsReadWrite: 组合接口

  设计原则：
  - 使用 FPC 默认接口（COM 风格，带引用计数）
  - 方法签名对齐 Rust trait
  - 支持组合使用

  用法示例：
    procedure ProcessReader(AReader: IFsRead);
    var
      Data: TBytes;
    begin
      Data := AReader.ReadBytes(1024);
      // 处理数据
    end;

    var
      F: TFile;
    begin
      F := TFile.Open('data.txt');
      try
        ProcessReader(F);  // TFile 实现了 IFsRead
      finally
        F.Free;
      end;
    end;
}

interface

uses
  SysUtils;

const
  // Seek 起始位置常量
  FS_SEEK_SET = 0;  // 从文件开头
  FS_SEEK_CUR = 1;  // 从当前位置
  FS_SEEK_END = 2;  // 从文件末尾

type
  // ============================================================================
  // IFsRead - 读取接口 (对标 Rust std::io::Read)
  // ============================================================================
  IFsRead = interface(IInterface)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // 读取到缓冲区，返回实际读取的字节数
    function Read(var ABuffer; ACount: Integer): Integer;

    // 读取指定数量的字节
    function ReadBytes(ACount: Integer): TBytes;

    // 读取全部内容
    function ReadAll: TBytes;

    // 读取为字符串
    function ReadString: string;
  end;

  // ============================================================================
  // IFsWrite - 写入接口 (对标 Rust std::io::Write)
  // ============================================================================
  IFsWrite = interface(IInterface)
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    // 写入缓冲区，返回实际写入的字节数
    function Write(const ABuffer; ACount: Integer): Integer;

    // 写入字节数组
    function WriteBytes(const AData: TBytes): Integer;

    // 写入字符串
    function WriteString(const AStr: string): Integer;

    // 刷新缓冲区
    procedure Flush;
  end;

  // ============================================================================
  // IFsSeek - 定位接口 (对标 Rust std::io::Seek)
  // ============================================================================
  IFsSeek = interface(IInterface)
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    // 定位到指定位置
    // AOrigin: FS_SEEK_SET, FS_SEEK_CUR, FS_SEEK_END
    function Seek(AOffset: Int64; AOrigin: Integer): Int64;

    // 获取当前位置
    function Position: Int64;

    // 获取流大小
    function Size: Int64;

    // 定位到开头
    procedure Rewind;

    // 定位到末尾，返回文件大小
    function SeekEnd: Int64;
  end;

  // ============================================================================
  // IFsReadSeek - 可定位的读取接口
  // ============================================================================
  IFsReadSeek = interface(IFsRead)
    ['{D4E5F6A7-B8C9-0123-DEF0-234567890123}']
    function Seek(AOffset: Int64; AOrigin: Integer): Int64;
    function Position: Int64;
    function Size: Int64;
    procedure Rewind;
    function SeekEnd: Int64;
  end;

  // ============================================================================
  // IFsWriteSeek - 可定位的写入接口
  // ============================================================================
  IFsWriteSeek = interface(IFsWrite)
    ['{E5F6A7B8-C9D0-1234-EF01-345678901234}']
    function Seek(AOffset: Int64; AOrigin: Integer): Int64;
    function Position: Int64;
    function Size: Int64;
    procedure Rewind;
    function SeekEnd: Int64;
  end;

  // ============================================================================
  // IFsReadWrite - 读写组合接口
  // ============================================================================
  IFsReadWrite = interface(IInterface)
    ['{F6A7B8C9-D0E1-2345-F012-456789012345}']
    // 读取方法
    function Read(var ABuffer; ACount: Integer): Integer;
    function ReadBytes(ACount: Integer): TBytes;
    function ReadAll: TBytes;
    function ReadString: string;

    // 写入方法
    function Write(const ABuffer; ACount: Integer): Integer;
    function WriteBytes(const AData: TBytes): Integer;
    function WriteString(const AStr: string): Integer;
    procedure Flush;

    // 定位方法
    function Seek(AOffset: Int64; AOrigin: Integer): Int64;
    function Position: Int64;
    function Size: Int64;
    procedure Rewind;
    function SeekEnd: Int64;
  end;

  // ============================================================================
  // IFsBufRead - 带缓冲的读取接口 (对标 Rust std::io::BufRead)
  // ============================================================================
  IFsBufRead = interface(IFsRead)
    ['{A7B8C9D0-E1F2-3456-0123-567890123456}']
    // 读取一行
    function ReadLine(out ALine: string): Boolean;

    // 缓冲区中剩余的字节数
    function BufferedBytes: Integer;

    // 是否到达末尾
    function IsEof: Boolean;
  end;

implementation

end.
