program ArticleToEpub;

uses
  System.StartUpCopy,
  FMX.Forms,
  SysUtils,
  FmMain in 'FmMain.pas' {Form1},
  FrmSettings in 'frames\FrmSettings.pas' {Frame1: TFrame},
  SettingsRepository in 'src\SettingsRepository.pas',
  FrmConverter in 'frames\FrmConverter.pas' {Frame2: TFrame},
  DMRestClient in 'src\DMRestClient.pas',
  ClientInterface in 'src\interfaces\ClientInterface.pas',
  SettingsInterface in 'src\interfaces\SettingsInterface.pas',
  Settings in 'src\Settings.pas',
  ClientFactory in 'src\ClientFactory.pas';

{$R *.res}

var
  MainForm: TForm1;

begin
  Application.Initialize;
  Application.CreateForm(TForm1, MainForm);
  Application.Run;
end.
