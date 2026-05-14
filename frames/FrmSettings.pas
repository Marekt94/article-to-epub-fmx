unit FrmSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, FMX.Objects, SettingsInterface,
  Settings;

type
  TFrame1 = class(TFrame)
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
  private
    { Private declarations }
  FRepo: ISettingsRepository;
  function ReadSettingsFromUi: TAppSettings;
  procedure ReadSettingsToUi(const AppSettings: TAppSettings);
  public
    { Public declarations }
  procedure Init(const ARepo: ISettingsRepository);
  procedure LoadFromRepo;
  procedure SaveToRepo;
  end;

implementation

{$R *.fmx}

{ TAppSettings }

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

end.
