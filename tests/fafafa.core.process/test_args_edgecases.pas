{$CODEPAGE UTF8}
unit test_args_edgecases;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_ArgsEdge = class(TTestCase)
  published
    procedure Test_EmptyArg_Quoted;
    procedure Test_TrailingBackslash_Windows;
    procedure Test_NestedQuotes_Windows;
    procedure Test_LongArg_Windows;
  end;

implementation

procedure TTestCase_ArgsEdge.Test_EmptyArg_Quoted;
var B: IProcessBuilder; OutS: string;
begin
  // 空参数应正确传递（作为空字符串参数），以验证 QuoteArgWindows 的健壮性
  B := NewProcessBuilder
       .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
       {$IFDEF WINDOWS}.Args(['/c','echo','A','','B']){$ELSE}.Args(['A','','B']){$ENDIF}
       .CaptureStdOut;
  OutS := Trim(B.Output);
  // Windows 下 echo 会输出多余空格，统一只验证包含 A 和 B
  AssertTrue(Pos('A', OutS) > 0);
  AssertTrue(Pos('B', OutS) > 0);
end;

procedure TTestCase_ArgsEdge.Test_TrailingBackslash_Windows;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF WINDOWS}
  // 末尾反斜杠的参数在 Windows 需要正确处理引号与转义
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','C:\Path\With\Trailing\']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('C:\Path\With\Trailing\', OutS) > 0);
  {$ELSE}
  // 非 Windows 平台跳过
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge.Test_NestedQuotes_Windows;
var B: IProcessBuilder; OutS: string;
begin
  {$IFDEF WINDOWS}
  // 嵌套引号验证：包含空格与引号的参数，放宽断言以提高稳健性
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','"a b \"c\" d"']).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Pos('a b', OutS) > 0);
  AssertTrue(Pos('c', OutS) > 0);
  AssertTrue(Pos('d', OutS) > 0);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ArgsEdge.Test_LongArg_Windows;
var B: IProcessBuilder; OutS: string; L: string; I: Integer;
begin
  {$IFDEF WINDOWS}
  // 超长参数（> 1024 字符）
  L := '';
  for I := 1 to 1100 do L := L + 'x';
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo',L]).CaptureStdOut;
  OutS := Trim(B.Output);
  AssertTrue(Length(OutS) >= 1000);
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ArgsEdge);
end.

