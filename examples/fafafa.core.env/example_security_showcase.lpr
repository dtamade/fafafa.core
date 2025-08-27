program example_security_showcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.env;

procedure Println(const s: string);
begin
  WriteLn(s);
end;

procedure DemoSecurityHelpers;
var
  testNames: array[0..7] of string;
  testValues: array[0..4] of string;
  i: Integer;
  name, value, masked: string;
begin
  WriteLn('=== Security Helpers Demo ===');
  
  // Test sensitive name detection
  testNames[0] := 'PATH';
  testNames[1] := 'API_KEY';
  testNames[2] := 'DATABASE_PASSWORD';
  testNames[3] := 'SECRET_TOKEN';
  testNames[4] := 'HOME';
  testNames[5] := 'SSL_PRIVATE_KEY';
  testNames[6] := 'AUTH_CREDENTIAL';
  testNames[7] := 'USER';
  
  WriteLn('--- Sensitive Name Detection ---');
  for i := 0 to High(testNames) do
  begin
    name := testNames[i];
    if env_is_sensitive_name(name) then
      Println(name + ' -> SENSITIVE')
    else
      Println(name + ' -> safe');
  end;
  
  // Test value masking
  testValues[0] := '';
  testValues[1] := 'abc';
  testValues[2] := 'abcd';
  testValues[3] := 'secret123';
  testValues[4] := 'very_long_secret_key_12345678';
  
  WriteLn('--- Value Masking ---');
  for i := 0 to High(testValues) do
  begin
    value := testValues[i];
    masked := env_mask_value(value);
    Println('"' + value + '" -> "' + masked + '"');
  end;
  
  // Test name validation
  WriteLn('--- Name Validation ---');
  Println('PATH -> ' + BoolToStr(env_validate_name('PATH'), True));
  Println('_PRIVATE -> ' + BoolToStr(env_validate_name('_PRIVATE'), True));
  Println('VAR123 -> ' + BoolToStr(env_validate_name('VAR123'), True));
  Println('123VAR -> ' + BoolToStr(env_validate_name('123VAR'), True));
  Println('VAR-NAME -> ' + BoolToStr(env_validate_name('VAR-NAME'), True));
  Println('VAR.NAME -> ' + BoolToStr(env_validate_name('VAR.NAME'), True));
  Println('"" -> ' + BoolToStr(env_validate_name(''), True));
end;

procedure DemoSecureLogging;
var
  envName, envValue, logValue: string;
  guard: TEnvOverrideGuard;
begin
  WriteLn('--- Secure Logging Demo ---');
  
  envName := 'DEMO_API_KEY';
  
  // Set up a demo sensitive environment variable
  guard := env_override(envName, 'sk-1234567890abcdef');
  try
    if env_has(envName) then
    begin
      envValue := env_get(envName);
      
      // Safe logging: mask sensitive values
      if env_is_sensitive_name(envName) then
      begin
        logValue := env_mask_value(envValue);
        Println('SECURE LOG: ' + envName + ' = ' + logValue);
      end
      else
      begin
        Println('NORMAL LOG: ' + envName + ' = ' + envValue);
      end;
    end;
  finally
    guard.Done;
  end;
end;

begin
  DemoSecurityHelpers;
  WriteLn;
  DemoSecureLogging;
  
  WriteLn;
  WriteLn('Security showcase completed.');
end.
