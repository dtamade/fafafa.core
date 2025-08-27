program example_align_exceptions;
{$APPTYPE CONSOLE}
{$MODE ObjFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.utils;

procedure Demo;
var
  P: Pointer;
begin
  GetMem(P, 64);
  try
    Writeln('示例: 对齐函数 AlignUp/AlignDown 的异常语义 (非 2 的幂 → EInvalidArgument)');

    // 正例：2 的幂对齐
    Writeln(Format('AlignUp(Ptr, 16) = %p', [AlignUp(P, 16)]));
    Writeln(Format('AlignDown(Ptr, 16) = %p', [AlignDown(P, 16)]));

    // 反例：非 2 的幂对齐，期望抛出 EInvalidArgument
    try
      AlignUp(P, 3);
      Writeln('ERROR: 预期抛出 EInvalidArgument，但未抛出');
    except
      on E: EInvalidArgument do Writeln('OK: AlignUp(P, 3) 抛出 EInvalidArgument: ', E.Message);
      on E: Exception do Writeln('ERROR: AlignUp(P, 3) 抛出非预期异常: ', E.ClassName, ' - ', E.Message);
    end;

    try
      AlignDown(P, 6);
      Writeln('ERROR: 预期抛出 EInvalidArgument，但未抛出');
    except
      on E: EInvalidArgument do Writeln('OK: AlignDown(P, 6) 抛出 EInvalidArgument: ', E.Message);
      on E: Exception do Writeln('ERROR: AlignDown(P, 6) 抛出非预期异常: ', E.ClassName, ' - ', E.Message);
    end;

  finally
    FreeMem(P);
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

