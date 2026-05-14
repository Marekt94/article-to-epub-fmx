unit SettingsRepository;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Types,
  System.IniFiles,
  System.NetEncoding,
  System.Hash,
  System.Generics.Collections,
  System.Threading,
  System.SyncObjs,
  System.Rtti,
  System.TypInfo,
  System.StrUtils,
  System.DateUtils,
  System.Diagnostics,
  System.Math,
  System.Variants,
  Settings,
  SettingsInterface;

type
  /// <summary>
  ///  Proste repozytorium: trzyma ustawienia w pliku JSON w Documents.
  ///  Dzięki temu działa na Android i Windows bez dodatkowych zależności.
  /// </summary>
  TJsonFileSettingsRepository = class(TInterfacedObject, ISettingsRepository)
  private
    FFilePath: string;
    function GetFilePath: string;
    class function FromJson(const AJson: string): TAppSettings; static;
    class function ToJson(const A: TAppSettings): string; static;
  public
    constructor Create(const AFilePath: string = '');
    function Load: TAppSettings;
    procedure Save(const ASettings: TAppSettings);
  end;

  /// <summary>
  ///  Repozytorium: trzyma ustawienia w pliku INI w Documents.
  ///  Najprostsze w utrzymaniu i wygodne do ręcznej edycji.
  /// </summary>
  TIniFileSettingsRepository = class(TInterfacedObject, ISettingsRepository)
  private
    FFilePath: string;
    function GetFilePath: string;
  public
    constructor Create(const AFilePath: string = '');
    function Load: TAppSettings;
    procedure Save(const ASettings: TAppSettings);
  end;

implementation

{ TJsonFileSettingsRepository }

constructor TJsonFileSettingsRepository.Create(const AFilePath: string);
begin
  inherited Create;
  FFilePath := AFilePath;
end;

function TJsonFileSettingsRepository.GetFilePath: string;
begin
  if not FFilePath.IsEmpty then
    Exit(FFilePath);

  Result := TPath.Combine(TPath.GetDocumentsPath, 'article-to-epub.settings.json');
end;

class function TJsonFileSettingsRepository.FromJson(const AJson: string): TAppSettings;
var
  O: TJSONObject;
begin
  Result := TAppSettings.Default;
  if AJson.Trim.IsEmpty then
    Exit;

  O := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    if O = nil then
      Exit;
    Result.ReceiverEmailsCsv := O.GetValue<string>('receiverEmailsCsv', '');
    Result.BackendBaseUrl := O.GetValue<string>('backendBaseUrl', '');
    Result.ApiKey := O.GetValue<string>('apiKey', '');
    Result.SenderEmail := O.GetValue<string>('senderEmail', '');
    Result.SenderAppPassword := O.GetValue<string>('senderAppPassword', '');
  finally
    O.Free;
  end;
end;

function TJsonFileSettingsRepository.Load: TAppSettings;
var
  P: string;
  Json: string;
begin
  P := GetFilePath;
  if not TFile.Exists(P) then
    Exit(TAppSettings.Default);

  Json := TFile.ReadAllText(P, TEncoding.UTF8);
  Result := FromJson(Json);
end;

procedure TJsonFileSettingsRepository.Save(const ASettings: TAppSettings);
var
  P: string;
  Json: string;
begin
  P := GetFilePath;
  Json := ToJson(ASettings);
  TFile.WriteAllText(P, Json, TEncoding.UTF8);
end;

class function TJsonFileSettingsRepository.ToJson(const A: TAppSettings): string;
var
  O: TJSONObject;
begin
  O := TJSONObject.Create;
  try
    O.AddPair('receiverEmailsCsv', A.ReceiverEmailsCsv);
    O.AddPair('backendBaseUrl', A.BackendBaseUrl);
    O.AddPair('apiKey', A.ApiKey);
    O.AddPair('senderEmail', A.SenderEmail);
    O.AddPair('senderAppPassword', A.SenderAppPassword);
    Result := O.ToJSON;
  finally
    O.Free;
  end;
end;

{ TIniFileSettingsRepository }

constructor TIniFileSettingsRepository.Create(const AFilePath: string);
begin
  inherited Create;
  FFilePath := AFilePath;
end;

function TIniFileSettingsRepository.GetFilePath: string;
begin
  if not FFilePath.IsEmpty then
    Exit(FFilePath);

  Result := TPath.Combine(TPath.GetDocumentsPath, 'article-to-epub.settings.ini');
end;

function TIniFileSettingsRepository.Load: TAppSettings;
var
  Ini: TIniFile;
  P: string;
begin
  Result := TAppSettings.Default;
  P := GetFilePath;
  if not TFile.Exists(P) then
    Exit;

  Ini := TIniFile.Create(P);
  try
    Result.ReceiverEmailsCsv := Ini.ReadString('Main', 'ReceiverEmailsCsv', Result.ReceiverEmailsCsv);
    Result.BackendBaseUrl := Ini.ReadString('Advanced', 'BackendBaseUrl', Result.BackendBaseUrl);
    Result.ApiKey := Ini.ReadString('Advanced', 'ApiKey', Result.ApiKey);
    Result.SenderEmail := Ini.ReadString('Advanced', 'SenderEmail', Result.SenderEmail);
    Result.SenderAppPassword := Ini.ReadString('Advanced', 'SenderAppPassword', Result.SenderAppPassword);
  finally
    Ini.Free;
  end;
end;

procedure TIniFileSettingsRepository.Save(const ASettings: TAppSettings);
var
  Ini: TIniFile;
  P: string;
begin
  P := GetFilePath;
  ForceDirectories(ExtractFilePath(P));

  Ini := TIniFile.Create(P);
  try
    Ini.WriteString('Main', 'ReceiverEmailsCsv', ASettings.ReceiverEmailsCsv);
    Ini.WriteString('Advanced', 'BackendBaseUrl', ASettings.BackendBaseUrl);
    Ini.WriteString('Advanced', 'ApiKey', ASettings.ApiKey);
    Ini.WriteString('Advanced', 'SenderEmail', ASettings.SenderEmail);
    Ini.WriteString('Advanced', 'SenderAppPassword', ASettings.SenderAppPassword);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
