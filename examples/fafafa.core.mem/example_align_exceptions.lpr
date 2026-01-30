program example_align_exceptions;
{$IFDEF WINDOWS}{$APPTYPE CONSOLE}{$ENDIF}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.utils;

procedure Demo;
var
  LPtr: Pointer;
begin
  GetMem(LPtr, 64);
  try
    Writeln('示例: 对齐函数 AlignUp/AlignDown 的异常语义 (非 2 的幂 -> EInvalidArgument)');

    // 正例：2 的幂对齐
    Writeln(Format('AlignUp(Ptr, 16) = %p', [AlignUp(LPtr, 16)]));
    Writeln(Format('AlignDown(Ptr, 16) = %p', [AlignDown(LPtr, 16)]));

    // 反例：非 2 的幂对齐，期望抛出 EInvalidArgument
    try
      AlignUp(LPtr, 3);
      Writeln('ERROR: 预期抛出 EInvalidArgument，但未抛出');
    except
      on E: EInvalidArgument do Writeln('OK: AlignUp(Ptr, 3) 抛出 EInvalidArgument: ', E.Message);
      on E: Exception do Writeln('ERROR: AlignUp(Ptr, 3) 抛出非预期异常: ', E.ClassName, ' - ', E.Message);
    end;

    try
      AlignDown(LPtr, 6);
      Writeln('ERROR: 预期抛出 EInvalidArgument，但未抛出');
    except
      on E: EInvalidArgument do Writeln('OK: AlignDown(Ptr, 6) 抛出 EInvalidArgument: ', E.Message);
      on E: Exception do Writeln('ERROR: AlignDown(Ptr, 6) 抛出非预期异常: ', E.ClassName, ' - ', E.Message);
    end;

  finally
    FreeMem(LPtr);
  end;
end;

begin
  try
    Demo;
  except
    on E: Exception do
    begin
      Writeln('示例运行异常: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
