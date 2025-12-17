unit fafafa.core.io.error;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.error - 结构化 IO 错误模型

  提供：
  - EIOError 扩展构造函数（含 Op/Path/Code/Cause）
  - IOErrorWrap: 从异常创建结构化 EIOError
  - IOErrorRetryable: 判断错误是否可重试

  参考: Rust std::io::Error
}

interface

uses
  SysUtils,
  fafafa.core.io.base;

{ 创建结构化 IO 错误的便捷函数
  
  用法：
    raise IOErrorWrap(ekNotFound, 'open', '/path/to/file', E);
}
function IOErrorWrap(AKind: TIOErrorKind; const AOp, APath: string; ACause: Exception): EIOError;

{ 判断错误类型是否可重试
  
  可重试错误：ekInterrupted, ekTimedOut, ekWouldBlock
}
function IOErrorRetryable(AKind: TIOErrorKind): Boolean;

implementation

function IOErrorWrap(AKind: TIOErrorKind; const AOp, APath: string; ACause: Exception): EIOError;
var
  CauseMsg: string;
  Code: Integer;
begin
  CauseMsg := '';
  Code := 0;

  if ACause <> nil then
  begin
    CauseMsg := ACause.Message;
    if ACause is EIOError then
      Code := EIOError(ACause).Code
    else if ACause is EInOutError then
      Code := EInOutError(ACause).ErrorCode;
  end;

  Result := EIOError.Create(AKind, AOp, APath, Code, CauseMsg);
end;

function IOErrorRetryable(AKind: TIOErrorKind): Boolean;
begin
  Result := AKind in [ekInterrupted, ekTimedOut, ekWouldBlock];
end;

end.
