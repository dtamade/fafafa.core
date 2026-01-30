# fafafa.core.archiver - 归档与压缩模块

## 模块概述

`fafafa.core.archiver` 提供跨平台、现代化的归档读写接口，目标覆盖 ZIP、TAR、TAR.GZ（后续可扩展 Zstd/7z 通过后端桥接）。接口优先、分层实现，遵循现有模块风格。

## 设计目标
- 跨平台：Windows/Unix 一致行为；时间戳统一 UTC
- 高性能：流式读写、零拷贝优先（Pascal TStream 为核心接口）
- 现代接口：Reader/Writer 分离、条目枚举 IArchiveReader.Next + IArchiveEntry
- 可扩展：后端可替换（ZIP/TAR/GZ 等）；保持 I* 接口稳定
- 错误模型：抛出 EArchiverError；与 fs 模块统一文档风格

## 模块结构
- src/fafafa.core.archiver.interfaces.pas
- src/fafafa.core.archiver.pas（门面与工厂）
- 后端预留（解耦“归档格式/压缩算法”）：
  - src/fafafa.core.archiver.tar.pas（Tar 实现，POSIX ustar/pax 头支持）
  - src/fafafa.core.archiver.zip.pas（Zip 实现，后续）
  - 压缩 Provider：
    - src/fafafa.core.archiver.codec.deflate.paszlib.pas（基于 RTL paszlib）
    - src/fafafa.core.archiver.codec.deflate.zlibdyn.pas（动态 zlib 绑定）
    - src/fafafa.core.archiver.codec.deflate.purepascal.pas（后续自研）

## 关键接口

```pascal
uses fafafa.core.archiver.interfaces;

type
  TCompressionAlgorithm = (caNone, caGZip, caDeflate, caZstd);

  ICompressionProvider = interface
    function Algorithm: TCompressionAlgorithm;
    function WrapEncode(const Dest: TStream): TStream;
    function WrapDecode(const Source: TStream): TStream;
  end;

  IArchiveEntry = interface
    function GetName: string;
    function GetSize: Int64;
    function GetModifiedUtc: TDateTime;
    function GetIsDirectory: Boolean;
  end;

  IArchiveReader = interface
    function Next(out Entry: IArchiveEntry): Boolean;
    procedure ExtractCurrentToStream(const Dest: TStream);
    procedure SkipCurrent;
    procedure Reset;
  end;

  IArchiveWriter = interface
    procedure AddFile(const FilePath, ArchivePath: string);
    procedure AddDirectory(const ArchivePath: string);
    procedure AddStream(const ArchivePath: string; const Source: TStream; const ModifiedUtc: TDateTime);
    procedure Finish;
  end;
```

## 与现代库对齐
- Rust：tar crate、zip crate（Reader/Builder 模式；streaming）
- Go：archive/zip、archive/tar + compress/gzip（io.Reader/Writer 风格）
- Java：java.util.zip、nio.file.Files.copy（InputStream/OutputStream 适配）

对齐策略：
- 流式 API：基于 TStream；不强依赖文件路径
- 条目枚举：Reader.Next 返回是否存在下一条目
- 可选元数据：权限/时间戳/符号链接等通过 Options 控制

## 时间戳与权限
- 时间戳统一使用 UTC（ModifiedUtc）
- Windows/Unix 权限差异通过 Options.StoreUnixPermissions 控制；默认关闭

## 压缩与格式的分层组合
- Format 只表示容器：afTar / afZip
- Compression 表示算法：caNone / caGZip / caDeflate / caZstd
- 组合示例：Tar + GZip、Tar（None）、Zip（Deflate/Store）

### 阶段推进
- M1：Tar（容器）+ GZip（Compression，由 Provider 提供）
- M2：Zip（容器）+ Deflate（Compression），逐步补 ZIP64/UTF‑8
- M3：Zstd（Compression，可选），与 Tar/Zip 组合


## 本轮策略更新要点

- 非可寻址流容错：Reader.Reset/Next 不强依赖 Seek；以流式消费为准
- GZip Seek 策略放宽（探测友好）：
  - Seek(0, soCurrent)：返回已读/已写的未压缩字节数
  - Seek(0, soBeginning)：返回 0
  - 其他寻址：返回 -1，不抛异常
- Finish 释放策略：
  - 当启用压缩（如 GZip）时，Writer 由门面适配器在 Finish 后释放外层压缩流，以确保写入 gzip trailer 并刷新
  - Tar Writer 自身不再直接释放压缩流，避免双重释放
- 错误语义：
  - tar: short read / short read payload 用于标注头或数据区短读
  - tar: unsafe path detected 用于路径安全校验失败

## 使用示例（草案）

```pascal
uses Classes, SysUtils, fafafa.core.archiver, fafafa.core.archiver.interfaces;

var
  Opt: TArchiveOptions;
  Ms: TMemoryStream;
  W: IArchiveWriter;
  R: IArchiveReader;
begin
  Ms := TMemoryStream.Create;
  try
    Opt.Format := afTar;
    Opt.Compression := caGZip; // 通过 Provider/Registry 选择实现
    Opt.CompressionLevel := 6;
    Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False;
    Opt.StoreTimestampsUtc := True;
    Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(Ms, Opt);
    // W.AddFile('README.md', 'doc/README.md');
    // W.Finish;

    Ms.Position := 0;
    R := CreateArchiveReader(Ms, afTar);
    // while R.Next(E) do R.ExtractCurrentToStream(...);
  finally
    Ms.Free;
  end;
end;
```

## 测试与示例
- 单元测试位置：tests/fafafa.core.archiver/
  - Tar 回环：Test_TarRoundtrip.Test_Tar_WriteRead_Roundtrip
  - Tar 目录/文件布局：Test_TarRoundtrip.Test_Tar_DirectoryAndFile_Layout
  - Tar 0 字节文件：Test_TarRoundtrip.Test_Tar_ZeroByteFile
  - Tar 空归档 EOF：Test_TarRoundtrip.Test_Tar_EmptyArchive_EOF
  - Tar+GZip 回环：Test_TarGZipRoundtrip.Test_TarGZip_WriteRead_Roundtrip
  - GZip trailer 校验：
    - Test_TarGZipRoundtrip.Test_GZip_Trailer_CRC_Mismatch
    - Test_TarGZipRoundtrip.Test_GZip_Trailer_Size_Mismatch
  - 异常路径：
    - 截断头部/数据：Test_TarExceptions.Test_Tar_Reader_TruncatedHeader/Payload
    - PAX 路径穿越：Test_TarPAX.Test_Tar_PathTraversal_Rejected_OnRead
- 快速运行：tests/fafafa.core.archiver/buildOrTest.bat（构建+运行全部用例）
- 例子：examples/fafafa.core.archiver/
  - CreateTarGz.pas：创建一个简单的 tar.gz
  - ExtractTarGz.pas：解压 tar.gz 到指定目录

## 后续计划
- 实现 tar 头读写（ustar+pax）与 gzip 流包装
- 提供 zip 后端的最小可用读写（Store+Deflate）
- 与 fafafa.core.fs 集成（WalkDir -> Writer.AddFile）
- 文档对齐与扩展示例、基准测试

