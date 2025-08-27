unit fafafa.core.fs.async.iface;

{$mode objfpc}{$H+}

{!
  IFsFileAsync 接口别名与异步操作类型（草案）
  - 目的：在不修改既有 IAsyncFile 的前提下，提供标准命名别名与后续扩展的选项类型
  - 不包含实现，仅类型声明；不破坏现有行为
}

interface

uses
  SysUtils,
  fafafa.core.thread.future,
  fafafa.core.thread.cancel,
  fafafa.core.fs.async;

type
  // 统一命名：将现有 IAsyncFile 别名为 IFsFileAsync，便于文档与调用方一致引用
  IFsFileAsync = IAsyncFile;

  // 复制选项（与同步 CopyTree 选项保持语义接近；用于异步 API 草案）
  TFsCopyAsyncOptions = record
    Overwrite: Boolean;
    PreserveTimes: Boolean;
    PreservePerms: Boolean;
    FollowSymlinks: Boolean;
    CopySymlinksAsLinks: Boolean;
  end;

  // 异步操作函数类型（供将来门面/工厂实现使用；本单元不提供实现）
  TCopyFileAsync = function(const Src, Dst: string; const Opts: TFsCopyAsyncOptions; const Token: ICancellationToken = nil): IFuture;
  TMoveFileAsync = function(const Src, Dst: string; const Overwrite: Boolean; const Token: ICancellationToken = nil): IFuture;

implementation

end.

