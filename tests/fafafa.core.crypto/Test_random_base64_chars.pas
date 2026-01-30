{$CODEPAGE UTF8}
unit Test_random_base64_chars;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;

// 说明：
// - 本测试验证 ISecureRandom 的 Base64/Base64Url 便捷函数字符集正确性与长度边界；
// - 注意：当前实现为“从 Base64 字符集随机采样”，非对字节流进行 Base64 编码；
//   因此不应断言输出能解码，仅校验字符集与长度。

function IsInSet_Base64(const S: string): Boolean;
function IsInSet_Base64Url(const S: string): Boolean;

implementation

function IsInSet_Base64(const S: string): Boolean;
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i: Integer; ch: Char;
begin
  Result := True;
  for i := 1 to Length(S) do begin
    ch := S[i];
    if Pos(ch, ALPHABET) = 0 then exit(False);
  end;
end;

function IsInSet_Base64Url(const S: string): Boolean;
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
var i: Integer; ch: Char;
begin
  Result := True;
  for i := 1 to Length(S) do begin
    ch := S[i];
    if Pos(ch, ALPHABET) = 0 then exit(False);
  end;
end;

type
  TTestCase_Random_Base64 = class(TTestCase)
  published
    procedure Test_Base64_Charset_And_Lengths;
    procedure Test_Base64Url_Charset_And_Lengths;
    procedure Test_Base64_Length_Boundary_Zero_ShouldBeEmpty;
  end;

{ TTestCase_Random_Base64 }

procedure TTestCase_Random_Base64.Test_Base64_Charset_And_Lengths;
var R: ISecureRandom; s: string; L: Integer; Lens: array[0..4] of Integer = (1, 2, 3, 16, 33);
begin
  R := GetSecureRandom;
  for L in Lens do begin
    s := R.GetBase64String(L);
    AssertEquals('len', L, Length(s));
    AssertTrue('charset base64', IsInSet_Base64(s));
  end;
end;

procedure TTestCase_Random_Base64.Test_Base64Url_Charset_And_Lengths;
var R: ISecureRandom; s: string; L: Integer; Lens: array[0..4] of Integer = (1, 2, 3, 16, 33);
begin
  R := GetSecureRandom;
  for L in Lens do begin
    s := R.GetBase64UrlString(L);
    AssertEquals('len', L, Length(s));
    AssertTrue('charset base64url', IsInSet_Base64Url(s));
  end;
end;

procedure TTestCase_Random_Base64.Test_Base64_Length_Boundary_Zero_ShouldBeEmpty;
var R: ISecureRandom; s1, s2: string;
begin
  R := GetSecureRandom;
  s1 := R.GetBase64String(0);
  s2 := R.GetBase64UrlString(0);
  AssertEquals('empty', 0, Length(s1));
  AssertEquals('empty', 0, Length(s2));
end;

initialization
  RegisterTest(TTestCase_Random_Base64);

end.

