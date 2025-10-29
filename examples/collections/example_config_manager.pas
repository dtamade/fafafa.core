program example_config_manager;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.linkedhashmap;

type
  { 配置管理器（保持插入顺序） }
  TConfigManager = class
  private
    FConfig: specialize ILinkedHashMap<string, string>;
  public
    constructor Create;
    procedure Load(const aKey, aValue: string);
    function Get(const aKey: string; const aDefault: string = ''): string;
    procedure Save(const aFileName: string);
    procedure Print;
  end;

constructor TConfigManager.Create;
begin
  FConfig := specialize MakeLinkedHashMap<string, string>();
end;

procedure TConfigManager.Load(const aKey, aValue: string);
begin
  FConfig.AddOrAssign(aKey, aValue);
end;

function TConfigManager.Get(const aKey: string; const aDefault: string): string;
begin
  if not FConfig.TryGetValue(aKey, Result) then
    Result := aDefault;
end;

procedure TConfigManager.Save(const aFileName: string);
var
  LFile: TextFile;
  LPair: specialize TPair<string, string>;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  try
    WriteLn(LFile, '# 配置文件（自动生成）');
    WriteLn(LFile, '# 保持插入顺序');
    WriteLn(LFile);
    
    for LPair in FConfig do
      WriteLn(LFile, LPair.Key, '=', LPair.Value);
  finally
    CloseFile(LFile);
  end;
  WriteLn('[保存] 配置已保存到: ', aFileName);
end;

procedure TConfigManager.Print;
var
  LPair: specialize TPair<string, string>;
begin
  WriteLn('--- 当前配置（按插入顺序）---');
  for LPair in FConfig do
    WriteLn('  ', LPair.Key, ' = ', LPair.Value);
end;

var
  LConfig: TConfigManager;
begin
  WriteLn('=== 配置管理器示例（保持顺序）===');
  WriteLn;
  
  LConfig := TConfigManager.Create;
  try
    // 场景1：加载配置
    WriteLn('--- 场景1：加载配置 ---');
    LConfig.Load('app.name', 'MyApplication');
    LConfig.Load('app.version', '1.0.0');
    LConfig.Load('server.host', 'localhost');
    LConfig.Load('server.port', '8080');
    LConfig.Load('db.host', 'localhost');
    LConfig.Load('db.port', '5432');
    LConfig.Load('db.name', 'mydb');
    WriteLn('已加载 7 项配置');
    WriteLn;
    
    LConfig.Print;
    WriteLn;
    
    // 场景2：读取配置
    WriteLn('--- 场景2：读取配置 ---');
    WriteLn('应用名称: ', LConfig.Get('app.name'));
    WriteLn('服务器端口: ', LConfig.Get('server.port'));
    WriteLn('未知配置: ', LConfig.Get('unknown.key', 'default_value'));
    WriteLn;
    
    // 场景3：保存到文件（保持插入顺序，便于人工编辑）
    WriteLn('--- 场景3：保存到文件 ---');
    LConfig.Save('/tmp/app.config');
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：LinkedHashMap 保证遍历顺序与插入顺序一致');
    WriteLn('     这对配置文件很重要（便于人工阅读和编辑）');
  finally
    LConfig.Free;
  end;
end.

