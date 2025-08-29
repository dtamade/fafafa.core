program test_cpuid_simple;

{$mode objfpc}{$H+}

uses
  SysUtils;

// Simple CPUID test
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
{$IFDEF CPUX86_64}
asm
  push rbx
  
  // Save output pointers
  push rcx    // EAX_Out
  push rdx    // EBX_Out  
  push r8     // ECX_Out
  push r9     // EDX_Out
  
  // Execute CPUID
  cpuid
  
  // Restore pointers and store results
  pop r9      // EDX_Out
  mov [r9], edx
  
  pop r8      // ECX_Out
  mov [r8], ecx
  
  pop rdx     // EBX_Out
  mov [rdx], ebx
  
  pop rcx     // EAX_Out
  mov [rcx], eax
  
  pop rbx
end;
{$ELSE}
asm
  push ebx
  push edi
  push esi
  
  // Save input EAX
  mov esi, eax
  
  // Execute CPUID
  cpuid
  
  // Store EAX result
  mov edi, [esp + 16]  // EAX_Out parameter
  mov [edi], eax
  
  // Store EBX result  
  mov edi, [esp + 20]  // EBX_Out parameter
  mov [edi], ebx
  
  // Store ECX result
  mov edi, [esp + 24]  // ECX_Out parameter
  mov [edi], ecx
  
  // Store EDX result
  mov edi, [esp + 28]  // EDX_Out parameter
  mov [edi], edx
  
  pop esi
  pop edi
  pop ebx
end;
{$ENDIF}

var
  outputFile: TextFile;
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

begin
  AssignFile(outputFile, 'cpuid_test_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('Simple CPUID Test');
    WriteLog('=================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    try
      WriteLog('Testing CPUID leaf 0 (vendor string)...');
      
      // Get vendor string
      CPUID(0, eax, ebx, ecx, edx);
      
      WriteLog('CPUID(0) results:');
      WriteLog('  EAX (max leaf): $' + IntToHex(eax, 8));
      WriteLog('  EBX: $' + IntToHex(ebx, 8));
      WriteLog('  ECX: $' + IntToHex(ecx, 8));
      WriteLog('  EDX: $' + IntToHex(edx, 8));
      
      // Construct vendor string
      Move(ebx, vendorString[0], 4);
      Move(edx, vendorString[4], 4);
      Move(ecx, vendorString[8], 4);
      vendorString[12] := #0;
      
      WriteLog('  Vendor: "' + string(vendorString) + '"');
      
      if eax >= 1 then
      begin
        WriteLog('');
        WriteLog('Testing CPUID leaf 1 (features)...');
        
        CPUID(1, eax, ebx, ecx, edx);
        
        WriteLog('CPUID(1) results:');
        WriteLog('  EAX (version): $' + IntToHex(eax, 8));
        WriteLog('  EBX (brand/cache): $' + IntToHex(ebx, 8));
        WriteLog('  ECX (features): $' + IntToHex(ecx, 8));
        WriteLog('  EDX (features): $' + IntToHex(edx, 8));
        
        WriteLog('');
        WriteLog('Feature flags:');
        WriteLog('  SSE: ' + BoolToStr((edx and (1 shl 25)) <> 0, True));
        WriteLog('  SSE2: ' + BoolToStr((edx and (1 shl 26)) <> 0, True));
        WriteLog('  SSE3: ' + BoolToStr((ecx and (1 shl 0)) <> 0, True));
        WriteLog('  SSSE3: ' + BoolToStr((ecx and (1 shl 9)) <> 0, True));
        WriteLog('  SSE4.1: ' + BoolToStr((ecx and (1 shl 19)) <> 0, True));
        WriteLog('  SSE4.2: ' + BoolToStr((ecx and (1 shl 20)) <> 0, True));
        WriteLog('  AVX: ' + BoolToStr((ecx and (1 shl 28)) <> 0, True));
        WriteLog('  FMA: ' + BoolToStr((ecx and (1 shl 12)) <> 0, True));
      end;
      
      WriteLog('');
      WriteLog('✅ CPUID test completed successfully');
      
    except
      on E: Exception do
      begin
        WriteLog('❌ CPUID test failed with exception: ' + E.Message);
      end;
    end;
    
    WriteLog('');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('CPUID test completed. Check cpuid_test_results.txt for results.');
end.
