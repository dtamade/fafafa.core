{
  Test_fafafa_core_id_p3_features.pas - P3 ID 生成器测试

  测试 NanoID, TypeID, XID, CUID2 功能
}

unit Test_fafafa_core_id_p3_features;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, DateUtils,
  fafafa.core.id.nanoid,
  fafafa.core.id.typeid,
  fafafa.core.id.xid,
  fafafa.core.id.cuid2;

type
  { NanoID 测试 }
  TTestNanoId = class(TTestCase)
  published
    procedure Test_Default_Length;
    procedure Test_Custom_Length;
    procedure Test_Custom_Alphabet;
    procedure Test_Predefined_Alphabets;
    procedure Test_Batch_Generation;
    procedure Test_Generator_Interface;
    procedure Test_Validation;
    procedure Test_Uniqueness;
  end;

  { TypeID 测试 }
  TTestTypeId = class(TTestCase)
  published
    procedure Test_Basic_Generation;
    procedure Test_Prefix_Validation;
    procedure Test_Encode_Decode_Roundtrip;
    procedure Test_Parse;
    procedure Test_Nil_TypeId;
    procedure Test_No_Prefix;
    procedure Test_Generator;
    procedure Test_Batch_Generation;
  end;

  { XID 测试 }
  TTestXid = class(TTestCase)
  published
    procedure Test_Basic_Generation;
    procedure Test_String_Encoding;
    procedure Test_Decode_Roundtrip;
    procedure Test_Component_Extraction;
    procedure Test_Comparison;
    procedure Test_Nil_Xid;
    procedure Test_Batch_Generation;
    procedure Test_Monotonic;
  end;

  { CUID2 测试 }
  TTestCuid2 = class(TTestCase)
  published
    procedure Test_Default_Length;
    procedure Test_Custom_Length;
    procedure Test_First_Char_Is_Letter;
    procedure Test_Valid_Characters;
    procedure Test_Uniqueness;
    procedure Test_Batch_Generation;
    procedure Test_Generator;
    procedure Test_Validation;
  end;

implementation

{ TTestNanoId }

procedure TTestNanoId.Test_Default_Length;
var
  Id: string;
begin
  Id := NanoId;
  AssertEquals('Default NanoID length should be 21', 21, Length(Id));
end;

procedure TTestNanoId.Test_Custom_Length;
var
  Id: string;
begin
  Id := NanoId(10);
  AssertEquals('Custom length 10', 10, Length(Id));

  Id := NanoId(50);
  AssertEquals('Custom length 50', 50, Length(Id));
end;

procedure TTestNanoId.Test_Custom_Alphabet;
var
  Id: string;
  I: Integer;
  C: Char;
begin
  Id := NanoIdCustom('abc', 20);
  AssertEquals('Custom alphabet length', 20, Length(Id));

  // 验证只包含 a, b, c
  for I := 1 to Length(Id) do
  begin
    C := Id[I];
    AssertTrue('Character should be a, b, or c', (C = 'a') or (C = 'b') or (C = 'c'));
  end;
end;

procedure TTestNanoId.Test_Predefined_Alphabets;
var
  Id: string;
  I: Integer;
  C: Char;
begin
  // URL Safe
  Id := NanoIdWithAlphabet(naUrlSafe, 21);
  AssertEquals('URL Safe length', 21, Length(Id));

  // Hex Lower
  Id := NanoIdWithAlphabet(naHexLower, 16);
  AssertEquals('Hex length', 16, Length(Id));
  for I := 1 to Length(Id) do
  begin
    C := Id[I];
    AssertTrue('Hex char should be 0-9 or a-f',
      ((C >= '0') and (C <= '9')) or ((C >= 'a') and (C <= 'f')));
  end;

  // Numbers only
  Id := NanoIdWithAlphabet(naNumbers, 10);
  AssertEquals('Numbers length', 10, Length(Id));
  for I := 1 to Length(Id) do
  begin
    C := Id[I];
    AssertTrue('Should be digit', (C >= '0') and (C <= '9'));
  end;
end;

procedure TTestNanoId.Test_Batch_Generation;
var
  Ids: TStringArray;
  I: Integer;
begin
  Ids := NanoIdN(100);
  AssertEquals('Should generate 100 IDs', 100, Length(Ids));

  for I := 0 to High(Ids) do
    AssertEquals('Each ID should be 21 chars', 21, Length(Ids[I]));
end;

procedure TTestNanoId.Test_Generator_Interface;
var
  Gen: INanoIdGenerator;
  Id: string;
  Ids: TStringArray;
begin
  Gen := CreateNanoIdGenerator(naAlphanumeric, 16);

  AssertEquals('Generator size should be 16', 16, Gen.Size);
  AssertEquals('Generator alphabet', NANOID_ALPHABET_ALPHANUMERIC, Gen.Alphabet);

  Id := Gen.Next;
  AssertEquals('Generated ID length', 16, Length(Id));

  Ids := Gen.NextN(5);
  AssertEquals('Batch size', 5, Length(Ids));
end;

procedure TTestNanoId.Test_Validation;
var
  Id: string;
begin
  Id := NanoId;
  AssertTrue('Valid NanoID', IsValidNanoId(Id));

  AssertFalse('Empty string is invalid', IsValidNanoId(''));
  AssertFalse('Wrong length is invalid', IsValidNanoId('abc', naUrlSafe, 21));

  // Test with expected size
  Id := NanoId(10);
  AssertTrue('Valid with expected size', IsValidNanoId(Id, naUrlSafe, 10));
  AssertFalse('Invalid with wrong expected size', IsValidNanoId(Id, naUrlSafe, 21));
end;

procedure TTestNanoId.Test_Uniqueness;
var
  Ids: TStringArray;
  I, J: Integer;
begin
  Ids := NanoIdN(1000);

  for I := 0 to High(Ids) - 1 do
    for J := I + 1 to High(Ids) do
      AssertFalse('IDs should be unique', Ids[I] = Ids[J]);
end;

{ TTestTypeId }

procedure TTestTypeId.Test_Basic_Generation;
var
  Id: string;
begin
  Id := TypeId('user');
  AssertTrue('Should start with prefix', Copy(Id, 1, 5) = 'user_');
  AssertEquals('Total length', 5 + 26, Length(Id)); // prefix + _ + 26 chars
end;

procedure TTestTypeId.Test_Prefix_Validation;
var
  Raised: Boolean;
begin
  // Valid prefixes
  AssertTrue('lowercase valid', IsValidTypeIdPrefix('user'));
  AssertTrue('empty valid', IsValidTypeIdPrefix(''));
  AssertTrue('long valid', IsValidTypeIdPrefix('abcdefghijklmnopqrstuvwxyz'));

  // Invalid prefixes
  AssertFalse('uppercase invalid', IsValidTypeIdPrefix('User'));
  AssertFalse('numbers invalid', IsValidTypeIdPrefix('user123'));
  AssertFalse('underscore invalid', IsValidTypeIdPrefix('user_name'));

  // Test exception on invalid prefix
  Raised := False;
  try
    TypeId('User123');
  except
    on E: EInvalidTypeIdPrefix do
      Raised := True;
  end;
  AssertTrue('Should raise on invalid prefix', Raised);
end;

procedure TTestTypeId.Test_Encode_Decode_Roundtrip;
var
  Id: string;
  Parts: TTypeIdParts;
  Id2: string;
begin
  Id := TypeId('account');
  Parts := ParseTypeId(Id);

  AssertTrue('Parse should succeed', Parts.Valid);
  AssertEquals('Prefix should match', 'account', Parts.Prefix);

  // Re-encode and compare
  Id2 := TypeIdFromUuid(Parts.Prefix, Parts.Uuid);
  AssertEquals('Roundtrip should produce same ID', Id, Id2);
end;

procedure TTestTypeId.Test_Parse;
var
  Id: string;
  Parts: TTypeIdParts;
begin
  Id := TypeId('order');
  AssertTrue('TryParse should succeed', TryParseTypeId(Id, Parts));
  AssertEquals('Prefix', 'order', Parts.Prefix);

  // Extract components
  AssertEquals('GetPrefix', 'order', TypeIdGetPrefix(Id));
end;

procedure TTestTypeId.Test_Nil_TypeId;
var
  Id: string;
  Parts: TTypeIdParts;
  I: Integer;
  AllZero: Boolean;
begin
  Id := TypeIdNil('test');
  Parts := ParseTypeId(Id);

  // Check UUID is all zeros
  AllZero := True;
  for I := 0 to 15 do
    if Parts.Uuid[I] <> 0 then
      AllZero := False;

  AssertTrue('Nil TypeID should have zero UUID', AllZero);
end;

procedure TTestTypeId.Test_No_Prefix;
var
  Id: string;
  Parts: TTypeIdParts;
begin
  Id := TypeId('');  // No prefix
  AssertEquals('No prefix length should be 26', 26, Length(Id));
  AssertTrue('Should not contain underscore', Pos('_', Id) = 0);

  Parts := ParseTypeId(Id);
  AssertEquals('Prefix should be empty', '', Parts.Prefix);
end;

procedure TTestTypeId.Test_Generator;
var
  Gen: ITypeIdGenerator;
  Id: string;
  Ids: TStringArray;
begin
  Gen := CreateTypeIdGenerator('customer');
  AssertEquals('Generator prefix', 'customer', Gen.Prefix);

  Id := Gen.Next;
  AssertTrue('Should start with customer_', Copy(Id, 1, 9) = 'customer_');

  Ids := Gen.NextN(10);
  AssertEquals('Batch size', 10, Length(Ids));
end;

procedure TTestTypeId.Test_Batch_Generation;
var
  Ids: TStringArray;
  I, J: Integer;
begin
  Ids := TypeIdN('item', 100);
  AssertEquals('Should generate 100', 100, Length(Ids));

  // Check uniqueness
  for I := 0 to High(Ids) - 1 do
    for J := I + 1 to High(Ids) do
      AssertFalse('IDs should be unique', Ids[I] = Ids[J]);
end;

{ TTestXid }

procedure TTestXid.Test_Basic_Generation;
var
  X: TXid96;
begin
  X := Xid;
  AssertFalse('Should not be nil', XidIsNil(X));
end;

procedure TTestXid.Test_String_Encoding;
var
  X: TXid96;
  S: string;
begin
  X := Xid;
  S := XidToString(X);
  AssertEquals('XID string length should be 20', 20, Length(S));
end;

procedure TTestXid.Test_Decode_Roundtrip;
var
  X1, X2: TXid96;
  S: string;
begin
  X1 := Xid;
  S := XidToString(X1);
  X2 := XidFromString(S);

  AssertTrue('Roundtrip should produce equal XIDs', XidEquals(X1, X2));
end;

procedure TTestXid.Test_Component_Extraction;
var
  X: TXid96;
  TS: TDateTime;
  Unix: Int64;
  MachId: UInt32;
  ProcId: Word;
  Counter: UInt32;
begin
  X := Xid;

  TS := XidTimestamp(X);
  Unix := XidUnixTime(X);
  MachId := XidMachineId(X);
  ProcId := XidProcessId(X);
  Counter := XidCounter(X);

  // Timestamp should be recent (within last minute)
  AssertTrue('Timestamp should be recent',
    Abs(SecondsBetween(TS, LocalTimeToUniversal(Now))) < 60);

  // Components should be in valid ranges
  AssertTrue('Machine ID should be 24-bit', MachId <= $FFFFFF);
  AssertTrue('Counter should be 24-bit', Counter <= $FFFFFF);
end;

procedure TTestXid.Test_Comparison;
var
  X1, X2: TXid96;
begin
  X1 := Xid;
  Sleep(1);
  X2 := Xid;

  // X2 should be greater (later timestamp or higher counter)
  AssertTrue('Later XID should be greater', XidCompare(X1, X2) <= 0);

  // Self comparison
  AssertEquals('Self comparison should be 0', 0, XidCompare(X1, X1));
end;

procedure TTestXid.Test_Nil_Xid;
var
  X: TXid96;
begin
  X := XidNil;
  AssertTrue('Nil XID should be nil', XidIsNil(X));

  AssertFalse('Regular XID should not be nil', XidIsNil(Xid));
end;

procedure TTestXid.Test_Batch_Generation;
var
  Ids: TStringArray;
  Xids: TXid96Array;
  I, J: Integer;
begin
  Ids := XidN(100);
  AssertEquals('Should generate 100 strings', 100, Length(Ids));

  Xids := XidBatchN(50);
  AssertEquals('Should generate 50 XIDs', 50, Length(Xids));

  // Check uniqueness
  for I := 0 to High(Ids) - 1 do
    for J := I + 1 to High(Ids) do
      AssertFalse('XIDs should be unique', Ids[I] = Ids[J]);
end;

procedure TTestXid.Test_Monotonic;
var
  Xids: TXid96Array;
  I: Integer;
begin
  Xids := XidBatchN(100);

  // XIDs generated in sequence should be monotonically increasing
  for I := 0 to High(Xids) - 1 do
    AssertTrue('XIDs should be monotonic', XidCompare(Xids[I], Xids[I+1]) <= 0);
end;

{ TTestCuid2 }

procedure TTestCuid2.Test_Default_Length;
var
  Id: string;
begin
  Id := Cuid2;
  AssertEquals('Default CUID2 length should be 24', 24, Length(Id));
end;

procedure TTestCuid2.Test_Custom_Length;
var
  Id: string;
begin
  Id := Cuid2(10);
  AssertEquals('Custom length 10', 10, Length(Id));

  Id := Cuid2(32);
  AssertEquals('Custom length 32', 32, Length(Id));
end;

procedure TTestCuid2.Test_First_Char_Is_Letter;
var
  Id: string;
  I: Integer;
  C: Char;
begin
  for I := 1 to 100 do
  begin
    Id := Cuid2;
    C := Id[1];
    AssertTrue('First char must be letter a-z',
      (C >= 'a') and (C <= 'z'));
  end;
end;

procedure TTestCuid2.Test_Valid_Characters;
var
  Id: string;
  I: Integer;
  C: Char;
begin
  Id := Cuid2;
  for I := 1 to Length(Id) do
  begin
    C := Id[I];
    AssertTrue('Character must be a-z or 0-9',
      ((C >= 'a') and (C <= 'z')) or ((C >= '0') and (C <= '9')));
  end;
end;

procedure TTestCuid2.Test_Uniqueness;
var
  Ids: TStringArray;
  I, J: Integer;
begin
  Ids := Cuid2N(1000);

  for I := 0 to High(Ids) - 1 do
    for J := I + 1 to High(Ids) do
      AssertFalse('CUID2s should be unique', Ids[I] = Ids[J]);
end;

procedure TTestCuid2.Test_Batch_Generation;
var
  Ids: TStringArray;
begin
  Ids := Cuid2N(100);
  AssertEquals('Should generate 100 CUID2s', 100, Length(Ids));
end;

procedure TTestCuid2.Test_Generator;
var
  Gen: ICuid2Generator;
  Id: string;
  Ids: TStringArray;
begin
  Gen := CreateCuid2Generator(16);
  AssertEquals('Generator length', 16, Gen.Length);

  Id := Gen.Next;
  AssertEquals('Generated ID length', 16, Length(Id));

  Ids := Gen.NextN(10);
  AssertEquals('Batch size', 10, Length(Ids));
end;

procedure TTestCuid2.Test_Validation;
var
  Id: string;
begin
  Id := Cuid2;
  AssertTrue('Valid CUID2', IsCuid2(Id));

  AssertFalse('Empty string invalid', IsCuid2(''));
  AssertFalse('Too short invalid', IsCuid2('a'));
  AssertFalse('Uppercase invalid', IsCuid2('ABC123'));
  AssertFalse('Starting with number invalid', IsCuid2('1abcdefghijklmnop'));
end;

initialization
  RegisterTest(TTestNanoId);
  RegisterTest(TTestTypeId);
  RegisterTest(TTestXid);
  RegisterTest(TTestCuid2);

end.
