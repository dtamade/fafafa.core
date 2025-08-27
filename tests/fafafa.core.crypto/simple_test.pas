program simple_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.crypto;

var
  LHash: IHashAlgorithm;
  LData: TBytes;
  LResult: TBytes;
  LExpected: string;
begin
  try
    WriteLn('Creating SHA256...');
    LHash := CreateSHA256;
    
    WriteLn('Preparing data...');
    LData := TEncoding.UTF8.GetBytes('abc');
    
    WriteLn('Calling Update...');
    if Length(LData) > 0 then
      LHash.Update(LData[0], Length(LData));
    
    WriteLn('Calling Finalize...');
    LResult := LHash.Finalize;
    
    LExpected := 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
    WriteLn('Expected: ', LExpected);
    WriteLn('Actual:   ', LowerCase(BytesToHex(LResult)));
    
    if LowerCase(BytesToHex(LResult)) = LExpected then
      WriteLn('SUCCESS!')
    else
      WriteLn('FAILED!');
      
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
