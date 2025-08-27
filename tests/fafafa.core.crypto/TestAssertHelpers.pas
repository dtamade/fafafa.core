{$CODEPAGE UTF8}
unit TestAssertHelpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit,
  fafafa.core.crypto; // for ENotSupported

type
  // Simple "procedure of object" alias for method-pointer based assertions
  TObjProc = procedure of object;

// Expect an exception of the given class from the provided procedure
procedure ExpectRaises(const AMsg: string; AEClass: ExceptClass; AProc: TObjProc);

// Expect ENotSupported from the provided procedure (helper for NotImplemented paths)
procedure ExpectNotSupported(AProc: TObjProc; const AMsg: string = '');

implementation

procedure ExpectRaises(const AMsg: string; AEClass: ExceptClass; AProc: TObjProc);
begin
  try
    if Assigned(AProc) then
      AProc()
    else
      raise Exception.Create('ExpectRaises: Proc is nil');
    raise Exception.Create(AMsg);
  except
    on E: Exception do
    begin
      if not E.InheritsFrom(AEClass) then
        raise Exception.CreateFmt('%s (expected %s, got %s)', [AMsg, AEClass.ClassName, E.ClassName]);
    end;
  end;
end;

procedure ExpectNotSupported(AProc: TObjProc; const AMsg: string);
var
  LMsg: string;
begin
  if AMsg = '' then
    LMsg := 'Expected ENotSupported'
  else
    LMsg := AMsg;
  ExpectRaises(LMsg, ENotSupported, AProc);
end;

end.

