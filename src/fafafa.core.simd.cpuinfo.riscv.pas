unit fafafa.core.simd.cpuinfo.riscv;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_RISCV_AVAILABLE}

uses
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.base;

type
  // RISC-V processor information structure
  TRISCVProcessorInfo = record
    Architecture: string;
    ISA: string;
    XLEN: Integer;
  end;

// === RISC-V 平台特定�?CPU 检�?===

// 检�?RISC-V 特�?function DetectRISCVFeatures: TRISCVFeatures;

// 检�?RISC-V 厂商和型�?procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);

// 获取 RISC-V 处理器信�?function GetRISCVProcessorInfo: TRISCVProcessorInfo;

// �?/proc/cpuinfo 解析 RISC-V 特性（Linux�?function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;

{$ENDIF}

implementation

{$IFDEF SIMD_RISCV_AVAILABLE}

uses
  SysUtils
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF};

function DetectRISCVFeatures: TRISCVFeatures;
{$IFDEF UNIX}
var
  cpuInfoContent: string;
  f: TextFile;
  line: string;
{$ENDIF}
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
  
  {$IFDEF UNIX}
  // �?Linux 上，�?/proc/cpuinfo 读取特�?  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(f, '/proc/cpuinfo');
      Reset(f);
      
      cpuInfoContent := '';
      while not Eof(f) do
      begin
        ReadLn(f, line);
        cpuInfoContent := cpuInfoContent + line + #10;
      end;
      
      CloseFile(f);
      
      // 解析特�?      Result := ParseRISCVFeaturesFromCpuInfo(cpuInfoContent);
    end;
  except
    // 如果读取失败，使用默认检�?  end;
  {$ENDIF}
end;

procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);
{$IFDEF UNIX}
var
  f: TextFile;
  line: string;
  key, value: string;
  colonPos: Integer;
{$ENDIF}
begin
  cpuInfo.Vendor := 'RISC-V';
  cpuInfo.Model := 'RISC-V Processor';
  
  {$IFDEF UNIX}
  // �?/proc/cpuinfo 读取处理器信�?  try
    if FileExists('/proc/cpuinfo') then
    begin
      AssignFile(f, '/proc/cpuinfo');
      Reset(f);
      
      while not Eof(f) do
      begin
        ReadLn(f, line);
        line := Trim(line);
        
        if line = '' then
          Continue;
          
        colonPos := Pos(':', line);
        if colonPos > 0 then
        begin
          key := Trim(Copy(line, 1, colonPos - 1));
          value := Trim(Copy(line, colonPos + 1, Length(line)));
          
          if key = 'vendor_id' then
          begin
            if value <> '' then
              cpuInfo.Vendor := value;
          end
          else if key = 'model name' then
          begin
            if value <> '' then
              cpuInfo.Model := value;
          end;
        end;
      end;
      
      CloseFile(f);
    end;
  except
    // 如果读取失败，使用默认�?  end;
  {$ENDIF}
end;

function GetRISCVProcessorInfo: TRISCVProcessorInfo;
begin
  FillChar(Result, SizeOf(TRISCVProcessorInfo), 0);
  
  {$IFDEF CPURISCV64}
  Result.Architecture := 'RV64';
  Result.XLEN := 64;
  {$ELSE}
  Result.Architecture := 'RV32';
  Result.XLEN := 32;
  {$ENDIF}
  
  Result.ISA := 'RISC-V';
  
  // TODO: 实现更详细的处理器信息检�?end;

function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;
var
  lines: TStringArray;
  line: string;
  isa: string;
  i: Integer;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
  
  lines := cpuInfo.Split([#10, #13]);
  
  for i := 0 to Length(lines) - 1 do
  begin
    line := Trim(lines[i]);
    
    if Pos('isa', LowerCase(line)) > 0 then
    begin
      var colonPos := Pos(':', line);
      if colonPos > 0 then
      begin
        isa := LowerCase(Trim(Copy(line, colonPos + 1, Length(line))));
        
        // 检查基础指令�?        if Pos('rv64', isa) > 0 then
          Result.HasRV64I := True
        else if Pos('rv32', isa) > 0 then
          Result.HasRV32I := True;
          
        // 检查扩�?        if Pos('m', isa) > 0 then
          Result.HasM := True;  // 乘法和除�?          
        if Pos('a', isa) > 0 then
          Result.HasA := True;  // 原子操作
          
        if Pos('f', isa) > 0 then
          Result.HasF := True;  // 单精度浮�?          
        if Pos('d', isa) > 0 then
          Result.HasD := True;  // 双精度浮�?          
        if Pos('c', isa) > 0 then
          Result.HasC := True;  // 压缩指令
          
        if Pos('v', isa) > 0 then
          Result.HasV := True;  // 向量扩展
      end;
    end;
  end;
end;

{$ELSE}

// === �?RISC-V 平台的存根实�?===

function DetectRISCVFeatures: TRISCVFeatures;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
end;

procedure DetectRISCVVendorAndModel(var cpuInfo: TCPUInfo);
begin
  cpuInfo.Vendor := 'Non-RISC-V';
  cpuInfo.Model := 'Non-RISC-V Processor';
end;

function GetRISCVProcessorInfo: TRISCVProcessorInfo;
begin
  FillChar(Result, SizeOf(TRISCVProcessorInfo), 0);
  Result.Architecture := 'Non-RISC-V';
  Result.ISA := 'Non-RISC-V';
  Result.XLEN := 0;
end;

function ParseRISCVFeaturesFromCpuInfo(const cpuInfo: string): TRISCVFeatures;
begin
  FillChar(Result, SizeOf(TRISCVFeatures), 0);
end;

{$ENDIF}

end.


