program test_rtti_record;

{$mode objfpc}{$H+}

uses
  SysUtils, TypInfo;

type
  TPersonRecord = record
    Name: string;
    Age: Integer;
    Salary: Double;
    Active: Boolean;
  end;

var
  ti: PTypeInfo;
  td: PTypeData;
  mf: PManagedField;
  i: Integer;
  p: PByte;
begin
  ti := TypeInfo(TPersonRecord);
  td := GetTypeData(ti);
  
  WriteLn('Record: ', ti^.Name);
  WriteLn('RecSize: ', td^.RecSize);
  WriteLn('TotalFieldCount: ', td^.TotalFieldCount);
  WriteLn('ManagedFldCount: ', td^.ManagedFldCount);
  WriteLn('');
  
  // 遍历 ManagedFields
  WriteLn('--- ManagedFields ---');
  p := PByte(@td^.ManagedFldCount);
  Inc(p, SizeOf(td^.ManagedFldCount));
  for i := 0 to td^.TotalFieldCount - 1 do
  begin
    mf := PManagedField(p);
    WriteLn('  [', i, '] Offset=', mf^.FldOffset);
    if mf^.TypeRef <> nil then
      WriteLn('       Type: ', PTypeInfo(mf^.TypeRef)^.Name, ' Kind=', Ord(PTypeInfo(mf^.TypeRef)^.Kind));
    Inc(p, SizeOf(TManagedField));
  end;
  
  WriteLn('');
  WriteLn('Done.');
end.
