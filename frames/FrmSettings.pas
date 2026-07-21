unit FrmSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, FMX.Objects, FMX.DialogService,
  SettingsInterface, Settings, ClientInterface, ClientFactory, Classes;

type
  TFrame1 = class(TFrame, IExecutingHandlers)
  RootScroll: TVertScrollBox;
  CardMain: TLayout;
  LblTitle: TLabel;
  LblReceivers: TLabel;
  EdtReceivers: TEdit;
  ExpAdvanced: TExpander;
  CardAdvanced: TLayout;
  LblBackend: TLabel;
  EdtBackend: TEdit;
  LblApiKey: TLabel;
  EdtApiKey: TEdit;
  LblSenderEmail: TLabel;
  EdtSenderEmail: TEdit;
  LblSenderPassword: TLabel;
  EdtSenderPassword: TEdit;
    Button1: TButton;
    BtnClearBrowserData: TButton;
  procedure Button1Click(Sender: TObject);
  procedure BtnClearBrowserDataClick(Sender: TObject);
  private
    FClient: IClient;
    FOnStart: TProc;
    FOnFinish: TProc<string>;
    FOnError: TProc<TObject>;
    FRepo: ISettingsRepository;
    function ReadSettingsFromUi: TAppSettings;
    procedure ReadSettingsToUi(const AppSettings: TAppSettings);
  public
      { Public declarations }
    procedure Init(const ARepo: ISettingsRepository);
    procedure LoadFromRepo;
    procedure SaveToRepo;

    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc<string>);
    procedure SetOnError(const AError: TProc<TObject>);
  end;

implementation

uses
  BrowserHtmlCapture;

{$R *.fmx}

{ TAppSettings }

procedure TFrame1.BtnClearBrowserDataClick(Sender: TObject);
var
  LError: string;
begin
  if ClearBrowserData(LError) then
    TDialogService.MessageDialog('Wyczyszczono dane przegl'#261'darki.',
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil)
  else
    TDialogService.MessageDialog(
      'Nie uda'#322'o si'#281' wyczy'#347'ci'#263' danych przegl'#261'darki.' + sLineBreak + LError,
      TMsgDlgType.mtError, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil);
end;

procedure TFrame1.Button1Click(Sender: TObject);
begin
  SaveToRepo;
  var AppSettings := FRepo.Load;
  FClient := TClientFactory.CreateInstance(AppSettings);
  var temp: IExecutingHandlers;
  if Supports(FClient, IExecutingHandlers, temp) then
  begin
    temp.OnStart := FOnStart;
    temp.OnSuccess := FOnFinish;
    temp.OnError := FOnError;
  end;
  FClient.Health
end;

procedure TFrame1.Init(const ARepo: ISettingsRepository);
begin
  FRepo := ARepo;
  LoadFromRepo;
end;

procedure TFrame1.LoadFromRepo;
var
  S: TAppSettings;
begin
  if FRepo = nil then
    Exit;
  S := FRepo.Load;
  ReadSettingsToUi(S);
end;

function TFrame1.ReadSettingsFromUi: TAppSettings;
begin
  Result := TAppSettings.Default;
  Result.ReceiverEmailsCsv := EdtReceivers.Text.Trim;
  Result.BackendBaseUrl := EdtBackend.Text.Trim;
  Result.ApiKey := EdtApiKey.Text.Trim;
  Result.SenderEmail := EdtSenderEmail.Text.Trim;
  Result.SenderAppPassword := EdtSenderPassword.Text; // nie trimujemy hasła
end;

procedure TFrame1.ReadSettingsToUi(const AppSettings: TAppSettings);
begin
  EdtReceivers.Text := AppSettings.ReceiverEmailsCsv;
  EdtBackend.Text := AppSettings.BackendBaseUrl;
  EdtApiKey.Text := AppSettings.ApiKey;
  EdtSenderEmail.Text := AppSettings.SenderEmail;
  EdtSenderPassword.Text := AppSettings.SenderAppPassword;
end;

procedure TFrame1.SaveToRepo;
begin
  if FRepo = nil then
    Exit;
  FRepo.Save(ReadSettingsFromUi);
end;

procedure TFrame1.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

procedure TFrame1.SetOnStart(const AProc: TProc);
begin
  FOnStart := AProc;
end;

procedure TFrame1.SetOnSuccess(const AProc: TProc<string>);
begin
  FOnFinish := AProc
end;

end.
