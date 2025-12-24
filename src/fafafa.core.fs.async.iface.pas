unit fafafa.core.fs.async.iface;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  异步文件操作公共接口与类型

  此单元包含所有异步模块共享的类型定义，解决以下模块的重复定义问题：
  - fafafa.core.fs.async.basic.pas
  - fafafa.core.fs.async.simple.pas
  - fafafa.core.fs.async.minimal.pas
  - fafafa.core.fs.async.pas

  同时提供 IFsFileAsync 接口别名与异步操作选项类型
}

interface

uses
  SysUtils,
  fafafa.core.thread.future,
  fafafa.core.thread.cancel;

type
  //==========================================================================
  // 公共类型（从 basic/minimal/simple 提取）
  //==========================================================================

  // 异步操作状态
  TAsyncStatus = (
    asRunning,     // 正在运行
    asCompleted,   // 已完成
    asFailed,      // 失败
    asCancelled    // 已取消
  );

  // 异步文件操作异常
  EAsyncFileError = class(Exception)
  private
    FErrorCode: Integer;
  public
    constructor Create(const AMessage: string); overload;
    constructor Create(const AMessage: string; AErrorCode: Integer); overload;
    property ErrorCode: Integer read FErrorCode;
  end;

  //==========================================================================
  // 接口别名与选项类型
  //==========================================================================

  // 复制选项（与同步 CopyTree 选项保持语义接近；用于异步 API 草案）
  TFsCopyAsyncOptions = record
    Overwrite: Boolean;
    PreserveTimes: Boolean;
    PreservePerms: Boolean;
    FollowSymlinks: Boolean;
    CopySymlinksAsLinks: Boolean;
  end;

  // 异步操作函数类型（供将来门面/工厂实现使用）
  TCopyFileAsyncFunc = function(const Src, Dst: string; const Opts: TFsCopyAsyncOptions; const Token: ICancellationToken = nil): IFuture;
  TMoveFileAsyncFunc = function(const Src, Dst: string; const Overwrite: Boolean; const Token: ICancellationToken = nil): IFuture;

implementation

{ EAsyncFileError }

constructor EAsyncFileError.Create(const AMessage: string);
begin
  inherited Create(AMessage);
  FErrorCode := 0;
end;

constructor EAsyncFileError.Create(const AMessage: string; AErrorCode: Integer);
begin
  inherited Create(AMessage);
  FErrorCode := AErrorCode;
end;

end.

