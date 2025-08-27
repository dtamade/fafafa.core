unit test_simple;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base;

type
  TTestClass = class
  public
    procedure DoSomething;
  end;

implementation

procedure TTestClass.DoSomething;
begin
  // 简单测试
end;

end.
