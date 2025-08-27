unit test_cipher_caesar_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.crypto.cipher.caesar;

procedure RegisterTests_Caesar_Basic;

implementation

type
  TCaesarTests = class(TTestCase)
  published
    procedure Test_Shift_Positive;
    procedure Test_Shift_Negative;
    procedure Test_Shift_Zero;
    procedure Test_NonLetters_Preserved;
  end;

procedure ExpectEq(const Name: string; const A, B: UnicodeString);
begin
  fpcunit.TAssert.AssertEquals(Name, A, B);
end;

procedure TCaesarTests.Test_Shift_Positive;
var plain, enc, dec: UnicodeString;
begin
  plain := 'Attack at dawn';
  enc := CaesarEncodeStr(plain, 3);
  ExpectEq('enc', 'Dwwdfn dw gdzq', enc);
  dec := CaesarDecodeStr(enc, 3);
  ExpectEq('dec', plain, dec);
end;

procedure TCaesarTests.Test_Shift_Negative;
var plain, enc, dec: UnicodeString;
begin
  plain := 'Hello, World!';
  enc := CaesarEncodeStr(plain, -5);
  ExpectEq('enc', 'Czggj, Rjmgy!', enc);
  dec := CaesarDecodeStr(enc, -5);
  ExpectEq('dec', plain, dec);
end;

procedure TCaesarTests.Test_Shift_Zero;
var plain: UnicodeString;
begin
  plain := 'AbcZzYy';
  ExpectEq('shift0', plain, CaesarEncodeStr(plain, 0));
  ExpectEq('shift0-dec', plain, CaesarDecodeStr(plain, 0));
end;

procedure TCaesarTests.Test_NonLetters_Preserved;
var plain, enc: UnicodeString;
begin
  plain := '1234-+= [] {} ~!@#$_中文_🙂';
  enc := CaesarEncodeStr(plain, 7);
  ExpectEq('nonletters', plain, enc);
end;

procedure RegisterTests_Caesar_Basic;
begin
  RegisterTest('crypto-cipher-caesar-basic', TCaesarTests.Suite);
end;

end.

