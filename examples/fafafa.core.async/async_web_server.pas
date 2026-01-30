program AsyncWebServer;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, StrUtils,
  fafafa.core.async,
  fafafa.core.thread.types;

{$MACRO ON}
{$DEFINE await := .GetValue}

type
  // HTTP 请求信息
  THttpRequest = record
    Method: string;
    Path: string;
    Headers: TStringList;
    Body: string;
  end;

  // HTTP 响应信息
  THttpResponse = record
    StatusCode: Integer;
    StatusText: string;
    Headers: TStringList;
    Body: string;
  end;

  // 简单的 HTTP 解析器
  THttpParser = class
  public
    class function ParseRequest(const Data: string): THttpRequest;
    class function BuildResponse(const Response: THttpResponse): string;
  end;

  // Web 服务器类
  TAsyncWebServer = class
  private
    FServer: IAsyncServer;
    FPort: Word;
    FRunning: Boolean;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function HandleClient(Client: IAsyncClient): IFuture<Boolean>;
    function ProcessRequest(const Request: THttpRequest): IFuture<THttpResponse>;
    function ServeStaticFile(const FilePath: string): IFuture<THttpResponse>;
    function HandleApiRequest(const Path: string; const Request: THttpRequest): IFuture<THttpResponse>;
    {$ENDIF}
  public
    constructor Create(Port: Word);
    destructor Destroy; override;
    
    function Start: IFuture<Boolean>;
    function Stop: IFuture<Boolean>;
    
    property Port: Word read FPort;
    property Running: Boolean read FRunning;
  end;

{ THttpParser }

class function THttpParser.ParseRequest(const Data: string): THttpRequest;
var
  Lines: TStringArray;
  RequestLine: string;
  Parts: TStringArray;
  i: Integer;
  HeaderLine: string;
  ColonPos: Integer;
  BodyStart: Integer;
begin
  Result.Headers := TStringList.Create;
  
  Lines := Data.Split([#13#10, #10]);
  if Length(Lines) = 0 then
    Exit;
  
  // 解析请求行
  RequestLine := Lines[0];
  Parts := RequestLine.Split([' ']);
  if Length(Parts) >= 2 then
  begin
    Result.Method := Parts[0];
    Result.Path := Parts[1];
  end;
  
  // 解析头部
  BodyStart := -1;
  for i := 1 to High(Lines) do
  begin
    HeaderLine := Lines[i];
    if HeaderLine = '' then
    begin
      BodyStart := i + 1;
      Break;
    end;
    
    ColonPos := Pos(':', HeaderLine);
    if ColonPos > 0 then
    begin
      Result.Headers.Values[Copy(HeaderLine, 1, ColonPos - 1)] := 
        Trim(Copy(HeaderLine, ColonPos + 1, MaxInt));
    end;
  end;
  
  // 解析主体
  if BodyStart >= 0 then
  begin
    Result.Body := '';
    for i := BodyStart to High(Lines) do
    begin
      if i > BodyStart then
        Result.Body := Result.Body + #13#10;
      Result.Body := Result.Body + Lines[i];
    end;
  end;
end;

class function THttpParser.BuildResponse(const Response: THttpResponse): string;
var
  i: Integer;
begin
  Result := Format('HTTP/1.1 %d %s'#13#10, [Response.StatusCode, Response.StatusText]);
  
  // 添加头部
  if Assigned(Response.Headers) then
  begin
    for i := 0 to Response.Headers.Count - 1 do
      Result := Result + Response.Headers[i] + #13#10;
  end;
  
  // 添加内容长度头部
  Result := Result + Format('Content-Length: %d'#13#10, [Length(Response.Body)]);
  Result := Result + 'Connection: close'#13#10;
  Result := Result + #13#10;
  
  // 添加主体
  Result := Result + Response.Body;
end;

{ TAsyncWebServer }

constructor TAsyncWebServer.Create(Port: Word);
begin
  inherited Create;
  FPort := Port;
  FRunning := False;
end;

destructor TAsyncWebServer.Destroy;
begin
  if FRunning then
    Stop await;
  inherited Destroy;
end;

function TAsyncWebServer.Start: IFuture<Boolean>;
begin
  WriteLn('启动 Web 服务器，端口: ', FPort);
  
  try
    FServer := Async.Listen('127.0.0.1', FPort) await;
    FRunning := True;
    
    WriteLn('服务器启动成功，访问 http://127.0.0.1:', FPort);
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 处理客户端连接
    FServer.Accept.ForEach(procedure(Client: IAsyncClient)
      begin
        WriteLn('新客户端连接: ', Client.RemoteAddress, ':', Client.RemotePort);
        HandleClient(Client); // 异步处理，不阻塞
      end);
    {$ENDIF}
    
    Result := TFuture<Boolean>.Completed(True);
    
  except
    on E: Exception do
    begin
      WriteLn('服务器启动失败: ', E.Message);
      Result := TFuture<Boolean>.Failed(E);
    end;
  end;
end;

function TAsyncWebServer.Stop: IFuture<Boolean>;
begin
  if not FRunning then
  begin
    Result := TFuture<Boolean>.Completed(True);
    Exit;
  end;
  
  WriteLn('停止 Web 服务器...');
  
  try
    if Assigned(FServer) then
      FServer.Stop await;
    FRunning := False;
    
    WriteLn('服务器已停止');
    Result := TFuture<Boolean>.Completed(True);
    
  except
    on E: Exception do
    begin
      WriteLn('服务器停止失败: ', E.Message);
      Result := TFuture<Boolean>.Failed(E);
    end;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TAsyncWebServer.HandleClient(Client: IAsyncClient): IFuture<Boolean>;
var
  RequestData: string;
  Request: THttpRequest;
  Response: THttpResponse;
  ResponseData: string;
begin
  try
    // 读取请求数据
    RequestData := Client.ReceiveText await;
    
    if RequestData = '' then
    begin
      Result := TFuture<Boolean>.Completed(True);
      Exit;
    end;
    
    WriteLn('收到请求: ', Copy(RequestData, 1, 100), '...');
    
    // 解析请求
    Request := THttpParser.ParseRequest(RequestData);
    
    // 处理请求
    Response := ProcessRequest(Request) await;
    
    // 发送响应
    ResponseData := THttpParser.BuildResponse(Response);
    Client.SendText(ResponseData) await;
    
    // 关闭连接
    Client.Close await;
    
    WriteLn('请求处理完成: ', Request.Method, ' ', Request.Path, ' -> ', Response.StatusCode);
    
    Result := TFuture<Boolean>.Completed(True);
    
  except
    on E: Exception do
    begin
      WriteLn('处理客户端错误: ', E.Message);
      Result := TFuture<Boolean>.Failed(E);
    end;
  end;
  
  // 清理
  if Assigned(Request.Headers) then
    Request.Headers.Free;
  if Assigned(Response.Headers) then
    Response.Headers.Free;
end;

function TAsyncWebServer.ProcessRequest(const Request: THttpRequest): IFuture<THttpResponse>;
var
  Response: THttpResponse;
begin
  Response.Headers := TStringList.Create;
  Response.Headers.Add('Content-Type: text/html; charset=utf-8');
  Response.Headers.Add('Server: AsyncPascal/1.0');
  
  try
    // 路由处理
    if Request.Path = '/' then
    begin
      // 首页
      Response.StatusCode := 200;
      Response.StatusText := 'OK';
      Response.Body := 
        '<!DOCTYPE html>' +
        '<html><head><title>AsyncPascal Web Server</title></head>' +
        '<body>' +
        '<h1>欢迎使用 AsyncPascal Web 服务器</h1>' +
        '<p>这是一个使用 FreePascal 异步 I/O 框架构建的 Web 服务器。</p>' +
        '<ul>' +
        '<li><a href="/hello">Hello World</a></li>' +
        '<li><a href="/time">当前时间</a></li>' +
        '<li><a href="/api/status">API 状态</a></li>' +
        '</ul>' +
        '</body></html>';
    end
    else if Request.Path = '/hello' then
    begin
      // Hello World 页面
      Response.StatusCode := 200;
      Response.StatusText := 'OK';
      Response.Body := 
        '<!DOCTYPE html>' +
        '<html><head><title>Hello World</title></head>' +
        '<body>' +
        '<h1>Hello, World!</h1>' +
        '<p>这是来自 AsyncPascal 的问候。</p>' +
        '<a href="/">返回首页</a>' +
        '</body></html>';
    end
    else if Request.Path = '/time' then
    begin
      // 时间页面
      Response.StatusCode := 200;
      Response.StatusText := 'OK';
      Response.Body := 
        '<!DOCTYPE html>' +
        '<html><head><title>当前时间</title></head>' +
        '<body>' +
        '<h1>当前时间</h1>' +
        '<p>' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '</p>' +
        '<a href="/">返回首页</a>' +
        '</body></html>';
    end
    else if StartsStr('/api/', Request.Path) then
    begin
      // API 请求
      Response := HandleApiRequest(Request.Path, Request) await;
    end
    else
    begin
      // 404 页面
      Response.StatusCode := 404;
      Response.StatusText := 'Not Found';
      Response.Body := 
        '<!DOCTYPE html>' +
        '<html><head><title>404 Not Found</title></head>' +
        '<body>' +
        '<h1>404 - 页面未找到</h1>' +
        '<p>请求的页面不存在。</p>' +
        '<a href="/">返回首页</a>' +
        '</body></html>';
    end;
    
    Result := TFuture<THttpResponse>.Completed(Response);
    
  except
    on E: Exception do
    begin
      Response.StatusCode := 500;
      Response.StatusText := 'Internal Server Error';
      Response.Body := 
        '<!DOCTYPE html>' +
        '<html><head><title>500 Internal Server Error</title></head>' +
        '<body>' +
        '<h1>500 - 内部服务器错误</h1>' +
        '<p>服务器处理请求时发生错误。</p>' +
        '</body></html>';
      Result := TFuture<THttpResponse>.Completed(Response);
    end;
  end;
end;

function TAsyncWebServer.HandleApiRequest(const Path: string; const Request: THttpRequest): IFuture<THttpResponse>;
var
  Response: THttpResponse;
  JsonResponse: string;
begin
  Response.Headers := TStringList.Create;
  Response.Headers.Add('Content-Type: application/json; charset=utf-8');
  Response.Headers.Add('Server: AsyncPascal/1.0');
  
  if Path = '/api/status' then
  begin
    // 状态 API
    Response.StatusCode := 200;
    Response.StatusText := 'OK';
    JsonResponse := Format(
      '{"status":"running","server":"AsyncPascal","version":"1.0","time":"%s","port":%d}',
      [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now), FPort]
    );
    Response.Body := JsonResponse;
  end
  else
  begin
    // API 未找到
    Response.StatusCode := 404;
    Response.StatusText := 'Not Found';
    Response.Body := '{"error":"API endpoint not found"}';
  end;
  
  Result := TFuture<THttpResponse>.Completed(Response);
end;
{$ENDIF}

// 主程序
var
  Server: TAsyncWebServer;
  Input: string;
begin
  WriteLn('AsyncPascal Web 服务器演示');
  WriteLn('===========================');
  
  Server := TAsyncWebServer.Create(8080);
  try
    // 启动服务器
    Server.Start await;
    
    WriteLn;
    WriteLn('服务器正在运行...');
    WriteLn('在浏览器中访问: http://127.0.0.1:8080');
    WriteLn('输入 "quit" 退出服务器');
    WriteLn;
    
    // 等待用户输入
    repeat
      Write('> ');
      ReadLn(Input);
      Input := LowerCase(Trim(Input));
    until (Input = 'quit') or (Input = 'exit') or (Input = 'q');
    
    // 停止服务器
    WriteLn('正在停止服务器...');
    Server.Stop await;
    
  except
    on E: Exception do
    begin
      WriteLn('服务器错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  Server.Free;
  Async.Shutdown;
  
  WriteLn('服务器已退出');
end.
