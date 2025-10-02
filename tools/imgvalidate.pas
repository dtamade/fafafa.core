program imgvalidate;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.graphics.validator;

procedure ShowHelp;
begin
  WriteLn('Image Validator and Repair Tool v1.0');
  WriteLn('Supports: BMP, PNG, JPEG, GIF, TIFF, TGA, ICO/CUR, WebP');
  WriteLn;
  WriteLn('Usage: imgvalidate [options] <image_file>');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  -h, --help       Show this help message');
  WriteLn('  -v, --validate   Validate image file (default)');
  WriteLn('  -r, --repair     Repair image file if possible');
  WriteLn('  -o <file>        Output file for repair (default: <input>.repaired.<ext>)');
  WriteLn('  -l <level>       Validation level: quick, standard, thorough (default: standard)');
  WriteLn('  -q, --quiet      Quiet mode, only show errors');
  WriteLn('  -d, --details    Show detailed validation report');
  WriteLn('  -b, --batch      Process all images in directory');
  WriteLn;
  WriteLn('Examples:');
  WriteLn('  imgvalidate photo.jpg');
  WriteLn('  imgvalidate -r -o fixed.jpg corrupted.jpg');
  WriteLn('  imgvalidate -l thorough -d image.png');
  WriteLn('  imgvalidate -b -r *.bmp');
end;

procedure PrintValidationResult(const AResult: TValidationResult; ADetailed: Boolean);
var
  i: Integer;
  SeverityStr: string;
begin
  WriteLn('Format: ', TImageValidator.GetFormatName(AResult.Format));
  WriteLn('File Size: ', AResult.FileSize, ' bytes');
  
  if (AResult.ImageWidth > 0) and (AResult.ImageHeight > 0) then
  begin
    WriteLn('Dimensions: ', AResult.ImageWidth, 'x', AResult.ImageHeight);
    WriteLn('Bit Depth: ', AResult.BitDepth);
    WriteLn('Has Alpha: ', AResult.HasAlpha);
  end;
  
  WriteLn('Valid: ', AResult.IsValid);
  WriteLn('Can Load: ', AResult.CanLoad);
  
  if Length(AResult.Issues) > 0 then
  begin
    WriteLn;
    WriteLn('Issues Found: ', Length(AResult.Issues));
    
    if ADetailed then
    begin
      WriteLn('---');
      for i := 0 to High(AResult.Issues) do
      begin
        case AResult.Issues[i].Severity of
          isInfo: SeverityStr := 'INFO';
          isWarning: SeverityStr := 'WARN';
          isError: SeverityStr := 'ERROR';
          isCritical: SeverityStr := 'CRITICAL';
        end;
        
        WriteLn(Format('[%s] %s: %s', [
          SeverityStr,
          AResult.Issues[i].Code,
          AResult.Issues[i].Message
        ]));
        
        if AResult.Issues[i].Offset >= 0 then
          WriteLn('  Offset: 0x', IntToHex(AResult.Issues[i].Offset, 8));
          
        if AResult.Issues[i].CanRepair then
          WriteLn('  Can Repair: Yes');
      end;
    end;
  end;
end;

procedure ProcessFile(const AFileName: string; AOptions: TStringList);
var
  Validator: TImageValidator;
  Result: TValidationResult;
  Level: TValidationLevel;
  Repair: Boolean;
  OutputFile: string;
  Quiet: Boolean;
  Detailed: Boolean;
  LevelStr: string;
  RepairSuccess: Boolean;
  CanRepair: Boolean;
  i: Integer;
begin
  // Parse options
  Repair := AOptions.IndexOf('-r') >= 0;
  if not Repair then
    Repair := AOptions.IndexOf('--repair') >= 0;
    
  Quiet := AOptions.IndexOf('-q') >= 0;
  if not Quiet then
    Quiet := AOptions.IndexOf('--quiet') >= 0;
    
  Detailed := AOptions.IndexOf('-d') >= 0;
  if not Detailed then
    Detailed := AOptions.IndexOf('--details') >= 0;
  
  // Get validation level
  Level := vlStandard;
  LevelStr := AOptions.Values['-l'];
  if LevelStr = '' then
    LevelStr := AOptions.Values['--level'];
    
  if LevelStr <> '' then
  begin
    if LowerCase(LevelStr) = 'quick' then
      Level := vlQuick
    else if LowerCase(LevelStr) = 'thorough' then
      Level := vlThorough;
  end;
  
  // Get output file
  OutputFile := AOptions.Values['-o'];
  if OutputFile = '' then
    OutputFile := AOptions.Values['--output'];
  
  if not Quiet then
  begin
    WriteLn('Processing: ', AFileName);
    WriteLn('---');
  end;
  
  Validator := TImageValidator.Create;
  try
    // Validate file
    Result := Validator.ValidateFile(AFileName, Level);
    
    if not Quiet then
      PrintValidationResult(Result, Detailed);
    
    // Repair if requested
    if Repair then
    begin
      if not Result.IsValid then
      begin
        CanRepair := False;
        for i := 0 to High(Result.Issues) do
        begin
          if Result.Issues[i].CanRepair then
          begin
            CanRepair := True;
            Break;
          end;
        end;
        
        if CanRepair then
        begin
          if not Quiet then
            WriteLn('Attempting repair...');
            
          RepairSuccess := Validator.RepairFile(AFileName, OutputFile);
          
          if RepairSuccess then
          begin
            if OutputFile = '' then
              OutputFile := ChangeFileExt(AFileName, '.repaired' + ExtractFileExt(AFileName));
              
            WriteLn('Repair successful: ', OutputFile);
            
            // Validate repaired file
            if not Quiet then
            begin
              WriteLn('Validating repaired file...');
              Result := Validator.ValidateFile(OutputFile, Level);
              PrintValidationResult(Result, False);
            end;
          end
          else
            WriteLn('Repair failed');
        end
        else
        begin
          if not Quiet then
            WriteLn('No repairable issues found');
        end;
      end
      else
      begin
        if not Quiet then
          WriteLn('File is valid, no repair needed');
      end;
    end;
    
  finally
    Validator.Free;
  end;
  
  if not Quiet then
    WriteLn;
end;

procedure ProcessBatch(const APattern: string; AOptions: TStringList);
var
  SearchRec: TSearchRec;
  Dir: string;
  Count: Integer;
begin
  Dir := ExtractFilePath(APattern);
  if Dir = '' then
    Dir := GetCurrentDir;
    
  Count := 0;
  
  if FindFirst(APattern, faAnyFile and not faDirectory, SearchRec) = 0 then
  begin
    repeat
      Inc(Count);
      ProcessFile(Dir + PathDelim + SearchRec.Name, AOptions);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
  
  if Count = 0 then
    WriteLn('No files found matching: ', APattern)
  else
    WriteLn('Processed ', Count, ' files');
end;

var
  Options: TStringList;
  InputFile: string;
  i: Integer;
  IsBatch: Boolean;
begin
  if ParamCount = 0 then
  begin
    ShowHelp;
    Exit;
  end;
  
  Options := TStringList.Create;
  try
    InputFile := '';
    IsBatch := False;
    
    // Parse command line
    i := 1;
    while i <= ParamCount do
    begin
      if (ParamStr(i) = '-h') or (ParamStr(i) = '--help') then
      begin
        ShowHelp;
        Exit;
      end
      else if (ParamStr(i) = '-o') or (ParamStr(i) = '--output') then
      begin
        if i < ParamCount then
        begin
          Inc(i);
          Options.Values['-o'] := ParamStr(i);
        end;
      end
      else if (ParamStr(i) = '-l') or (ParamStr(i) = '--level') then
      begin
        if i < ParamCount then
        begin
          Inc(i);
          Options.Values['-l'] := ParamStr(i);
        end;
      end
      else if (ParamStr(i) = '-b') or (ParamStr(i) = '--batch') then
      begin
        Options.Add('-b');
        IsBatch := True;
      end
      else if ParamStr(i)[1] = '-' then
      begin
        Options.Add(ParamStr(i));
      end
      else
      begin
        InputFile := ParamStr(i);
      end;
      Inc(i);
    end;
    
    if InputFile = '' then
    begin
      WriteLn('Error: No input file specified');
      WriteLn;
      ShowHelp;
      Exit;
    end;
    
    // Process file(s)
    if IsBatch then
      ProcessBatch(InputFile, Options)
    else
    begin
      if not FileExists(InputFile) then
      begin
        WriteLn('Error: File not found: ', InputFile);
        Exit;
      end;
      ProcessFile(InputFile, Options);
    end;
    
  finally
    Options.Free;
  end;
end.