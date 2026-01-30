program example_session_manager;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap;

type
  TUserSession = record
    SessionID: string;
    UserID: Integer;
    Username: string;
    LoginTime: TDateTime;
    LastActivity: TDateTime;
  end;

  { 会话管理器 }
  TSessionManager = class
  private
    FSessions: specialize IHashMap<string, TUserSession>;
    function GenerateSessionID: string;
  public
    constructor Create;
    function Login(aUserID: Integer; const aUsername: string): string;
    procedure UpdateActivity(const aSessionID: string);
    function GetSession(const aSessionID: string; out aSession: TUserSession): Boolean;
    procedure Logout(const aSessionID: string);
    procedure CleanupExpired(aTimeoutMinutes: Integer);
    procedure PrintActiveSessions;
  end;

constructor TSessionManager.Create;
begin
  FSessions := specialize MakeHashMap<string, TUserSession>();
end;

function TSessionManager.GenerateSessionID: string;
var
  LGUID: TGUID;
begin
  CreateGUID(LGUID);
  Result := GUIDToString(LGUID);
end;

function TSessionManager.Login(aUserID: Integer; const aUsername: string): string;
var
  LSession: TUserSession;
begin
  Result := GenerateSessionID;
  LSession.SessionID := Result;
  LSession.UserID := aUserID;
  LSession.Username := aUsername;
  LSession.LoginTime := Now;
  LSession.LastActivity := Now;
  
  FSessions.Add(Result, LSession);
  WriteLn(Format('[登录] 用户 %s (ID: %d) - 会话: %s', [
    aUsername, aUserID, Copy(Result, 1, 8) + '...'
  ]));
end;

procedure TSessionManager.UpdateActivity(const aSessionID: string);
var
  LSession: TUserSession;
begin
  if FSessions.TryGetValue(aSessionID, LSession) then
  begin
    LSession.LastActivity := Now;
    FSessions.AddOrAssign(aSessionID, LSession);
  end;
end;

function TSessionManager.GetSession(const aSessionID: string; out aSession: TUserSession): Boolean;
begin
  Result := FSessions.TryGetValue(aSessionID, aSession);
  if Result then
    UpdateActivity(aSessionID);
end;

procedure TSessionManager.Logout(const aSessionID: string);
var
  LSession: TUserSession;
begin
  if FSessions.TryGetValue(aSessionID, LSession) then
  begin
    WriteLn(Format('[登出] 用户 %s', [LSession.Username]));
    FSessions.Remove(aSessionID);
  end;
end;

procedure TSessionManager.CleanupExpired(aTimeoutMinutes: Integer);
var
  LPair: specialize TPair<string, TUserSession>;
  LExpiredIDs: specialize IVec<string>;
  LSessionID: string;
  LTimeoutThreshold: TDateTime;
begin
  LTimeoutThreshold := Now - (aTimeoutMinutes / (24 * 60));
  LExpiredIDs := specialize MakeVec<string>();
  
  // 查找过期会话
  for LPair in FSessions do
    if LPair.Value.LastActivity < LTimeoutThreshold then
      LExpiredIDs.Append(LPair.Key);
  
  // 删除过期会话
  for LSessionID in LExpiredIDs do
  begin
    WriteLn(Format('[过期] 会话 %s 已超时', [Copy(LSessionID, 1, 8) + '...']));
    FSessions.Remove(LSessionID);
  end;
  
  if LExpiredIDs.GetCount > 0 then
    WriteLn(Format('已清理 %d 个过期会话', [LExpiredIDs.GetCount]));
end;

procedure TSessionManager.PrintActiveSessions;
var
  LPair: specialize TPair<string, TUserSession>;
begin
  WriteLn(Format('--- 活跃会话 (%d 个) ---', [FSessions.GetCount]));
  for LPair in FSessions do
    WriteLn(Format('  %s: %s (最后活动: %s)', [
      Copy(LPair.Key, 1, 8) + '...',
      LPair.Value.Username,
      FormatDateTime('hh:nn:ss', LPair.Value.LastActivity)
    ]));
end;

var
  LManager: TSessionManager;
  LSession1, LSession2, LSession3: string;
  LSessionData: TUserSession;
begin
  WriteLn('=== 会话管理器示例 ===');
  WriteLn;
  
  LManager := TSessionManager.Create;
  try
    // 场景1：用户登录
    WriteLn('--- 场景1：用户登录 ---');
    LSession1 := LManager.Login(1001, 'alice');
    LSession2 := LManager.Login(1002, 'bob');
    LSession3 := LManager.Login(1003, 'charlie');
    WriteLn;
    
    LManager.PrintActiveSessions;
    WriteLn;
    
    // 场景2：验证会话
    WriteLn('--- 场景2：验证会话 ---');
    if LManager.GetSession(LSession1, LSessionData) then
      WriteLn(Format('会话有效: 用户 %s (ID: %d)', [
        LSessionData.Username, LSessionData.UserID
      ]));
    WriteLn;
    
    // 场景3：用户登出
    WriteLn('--- 场景3：用户登出 ---');
    LManager.Logout(LSession2);
    WriteLn;
    
    LManager.PrintActiveSessions;
    WriteLn;
    
    // 场景4：清理过期会话（模拟）
    WriteLn('--- 场景4：清理过期会话 ---');
    WriteLn('注意：实际使用中应定期调用 CleanupExpired');
    LManager.CleanupExpired(30); // 30分钟超时
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：HashMap 提供 O(1) 会话查找，适合高并发场景');
  finally
    LManager.Free;
  end;
end.

