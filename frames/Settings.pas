unit Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, FMX.Objects;

type
  TAppSettings = record
    ReceiverEmailsCsv: string;
    BackendBaseUrl: string;
    ApiKey: string;
    SenderEmail: string;
    SenderAppPassword: string;
    class function Default: TAppSettings; static;
  end;

  ISettingsRepository = interface
    ['{9E9A6F64-2F6D-4D7E-8B0B-96C6D5A6A7B1}']
    function Load: TAppSettings;
    procedure Save(const ASettings: TAppSettings);
  end;

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
  public
    { Public declarations }
  procedure Bind(const ARepo: ISettingsRepository);
  procedure LoadFromRepo;
  procedure SaveToRepo;
  end;

implementation

{$R *.fmx}

{ TAppSettings }

class function TAppSettings.Default: TAppSettings;
begin
  Result.ReceiverEmailsCsv := '';
  Result.BackendBaseUrl := '';
  Result.ApiKey := '';
  Result.SenderEmail := '';
  Result.SenderAppPassword := '';
end;

procedure TFrame1.Bind(const ARepo: ISettingsRepository);
begin
  FRepo := ARepo;
end;

procedure TFrame1.LoadFromRepo;
var
  S: TAppSettings;
begin
  if FRepo = nil then
    Exit;
  S := FRepo.Load;
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

procedure TFrame1.SaveToRepo;
begin
  if FRepo = nil then
    Exit;
  FRepo.Save(ReadSettingsFromUi);
end;

end.
