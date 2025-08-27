{$CODEPAGE UTF8}
unit fafafa.core.test.runner;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, consoletestrunner;

procedure ConfigureRunner(AApp: TTestRunner);

implementation

procedure ConfigureRunner(AApp: TTestRunner);
var
  Fmt, OutFile: String;
begin
  if AApp=nil then Exit;
  // 默认 plain；支持通过环境变量/参数切换
  Fmt := GetEnvironmentVariable('FAFAFA_TEST_FORMAT');
  if Fmt='' then Fmt := 'plain';
  if SameText(Fmt, 'plain') then
  begin
    DefaultFormat := fPlain;
  end
  else if SameText(Fmt, 'xml') then
  begin
    DefaultFormat := fXML;
  end
  else if SameText(Fmt, 'junit') then
  begin
    DefaultFormat := fJUnit;
  end
  else
  begin
    DefaultFormat := fPlain;
  end;

  // 输出文件（用于 xml/junit），可选环境变量 FAFAFA_TEST_OUT
  OutFile := GetEnvironmentVariable('FAFAFA_TEST_OUT');
  if (OutFile<>'') and (DefaultFormat in [fXML, fJUnit]) then
  begin
    try
      AssignFile(Output, OutFile);
      Rewrite(Output);
    except
      on E: Exception do
        Writeln(StdErr, '[runner] cannot open output file: ', OutFile, ' error=', E.Message);
    end;
  end;
end;

end.

