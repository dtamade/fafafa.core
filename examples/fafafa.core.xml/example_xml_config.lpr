{$CODEPAGE UTF8}
program example_xml_config;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.xml;

const
  SampleCfg =
    '<?xml version="1.0"?>' +
    '<config xmlns="urn:cfg" xmlns:f="urn:feature">' +
      '<server host="127.0.0.1" port="8080"/>' +
      '<database>' +
        '<user>admin</user>' +
        '<password>secret</password>' +
      '</database>' +
      '<features>' +
        '<f:toggle name="fast-path" enabled="true"/>' +
        '<f:toggle name="experimental" enabled="false"/>' +
      '</features>' +
    '</config>';

procedure ParseConfig;
var
  R: IXmlReader;
  InDatabase, InUser, InPassword: Boolean;
  Host, Port, DbUser, DbPass: String;
  FeatName, FeatEnabled: String;
  EnabledCount: Integer = 0;
begin
  R := CreateXmlReader.ReadFromString(SampleCfg, [xrfIgnoreWhitespace, xrfIgnoreComments]);
  InDatabase := False; InUser := False; InPassword := False;
  while R.Read do
  begin
    case R.Token of
      xtStartElement:
        begin
          if R.LocalName = 'server' then
          begin
            if R.TryGetAttribute('host', Host) then ;
            if R.TryGetAttribute('port', Port) then ;
          end
          else if R.LocalName = 'database' then
            InDatabase := True
          else if InDatabase and (R.LocalName = 'user') then
            InUser := True
          else if InDatabase and (R.LocalName = 'password') then
            InPassword := True
          else if R.LocalName = 'toggle' then
          begin
            if R.TryGetAttribute('name', FeatName) and R.TryGetAttribute('enabled', FeatEnabled) then
            begin
              if SameText(FeatEnabled, 'true') then Inc(EnabledCount);
              WriteLn('Feature: ', FeatName, ' = ', FeatEnabled);
            end;
          end;
        end;
      xtText:
        begin
          if InUser then DbUser := R.Value
          else if InPassword then DbPass := R.Value;
        end;
      xtEndElement:
        begin
          if R.LocalName = 'database' then InDatabase := False
          else if InUser and (R.LocalName = 'user') then InUser := False
          else if InPassword and (R.LocalName = 'password') then InPassword := False;
        end;
    end;
  end;
  WriteLn('Server = ', Host, ':', Port);
  WriteLn('DB User = ', DbUser, ' / Pass = ', DbPass);
  WriteLn('Enabled features = ', EnabledCount);
end;

procedure WriteModifiedConfig;
var
  W: IXmlWriter;
  S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0', 'UTF-8');
  W.StartElementNS('', 'config', 'urn:cfg');

  // server
  W.StartElement('server');
  W.WriteAttribute('host', '0.0.0.0');
  W.WriteAttribute('port', '9090');
  W.EndElement;

  // database
  W.StartElement('database');
  W.StartElement('user');
  W.WriteString('admin');
  W.EndElement; // user
  W.StartElement('password');
  W.WriteString('secret');
  W.EndElement; // password
  W.EndElement; // database

  // features with prefix
  W.StartElementNS('f', 'features', 'urn:feature'); // just to show ns write
  W.StartElementNS('f', 'toggle', 'urn:feature');
  W.WriteAttribute('name', 'fast-path');
  W.WriteAttribute('enabled', 'true');
  W.EndElement;
  W.StartElementNS('f', 'toggle', 'urn:feature');
  W.WriteAttribute('name', 'experimental');
  W.WriteAttribute('enabled', 'false');
  W.EndElement;
  W.EndElement; // f:features

  W.EndDocument;
  S := W.WriteToString([xwfPretty]);
  WriteLn(S);
end;

begin
  try
    ParseConfig;
    WriteLn;
    WriteModifiedConfig;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

