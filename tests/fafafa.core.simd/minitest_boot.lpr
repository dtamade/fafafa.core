program minitest_boot;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd;

begin
  try
    Writeln('BOOT: start');
    Writeln('SimdInfo=', SimdInfo);
    Writeln('BOOT: end');
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

