unit FrmBrowser;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.WebBrowser, ClientInterface, Settings,
  ClientFactory, SettingsInterface, Classes;

type
  TFrame3 = class(TFrame, IExecutingHandlers)
    BtnConvert: TButton;
    WebBrowser1: TWebBrowser;
    procedure BtnConvertClick(Sender: TObject);
  private
    FClient: IClient;
    FOnStart: TProc;
    FOnFinish: TProc<string>;
    FOnError: TProc<TObject>;
    FSettingsRepo: ISettingsRepository;
    FOnClose: TProc;
    FInitialUrl: string;
  public
    procedure Init(const ARepo: ISettingsRepository);
    procedure OpenUrl(const AUrl: string);
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc<string>);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
    property OnClose: TProc read FOnClose write FOnClose;
  end;

implementation

uses
  BrowserHtmlCapture;

{$R *.fmx}

procedure TFrame3.Init(const ARepo: ISettingsRepository);
begin
  FSettingsRepo := ARepo;
end;

procedure TFrame3.OpenUrl(const AUrl: string);
begin
  if not BrowserEngineAvailable then
  begin
    // Wracamy do konwertera i pokazujemy blad jeszcze przed wczytaniem strony.
    if Assigned(FOnClose) then
      FOnClose;
    if Assigned(FOnError) then
      FOnError(Exception.Create(SBrowserEngineUnavailable));
    Exit;
  end;
  var LUrl := AUrl.Trim;
  if not (LUrl.StartsWith('http://', True) or LUrl.StartsWith('https://', True)) then
    LUrl := 'https://' + LUrl;
  FInitialUrl := LUrl;
  WebBrowser1.Navigate(LUrl);
end;

procedure TFrame3.BtnConvertClick(Sender: TObject);
begin
  var LUrl := GetCurrentUrl(WebBrowser1);
  if (LUrl = '') or LUrl.StartsWith('about:', True) then
    LUrl := FInitialUrl;
  CaptureHtml(WebBrowser1,
    procedure(const AHtml, AError: string)
    begin
      if AError <> '' then
      begin
        if Assigned(FOnError) then
          FOnError(Exception.Create(AError));
        Exit;
      end;
      // Powrot na zakladke konwertera zanim pokaze sie spinner/dialog:
      // natywny WebView maluje sie nad tresc FMX i by je zaslonil.
      if Assigned(FOnClose) then
        FOnClose;
      var AppSettings := FSettingsRepo.Load;
      FClient := TClientFactory.CreateInstance(AppSettings);
      var temp: IExecutingHandlers;
      if Supports(FClient, IExecutingHandlers, temp) then
      begin
        temp.OnStart := FOnStart;
        temp.OnSuccess := FOnFinish;
        temp.OnError := FOnError;
      end;
      FClient.ConvertHtml(AHtml, LUrl, AppSettings.ReceiverEmailsCsv);
    end);
end;

procedure TFrame3.SetOnStart(const AProc: TProc);
begin
  FOnStart := AProc;
end;

procedure TFrame3.SetOnSuccess(const AProc: TProc<string>);
begin
  FOnFinish := AProc;
end;

procedure TFrame3.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

end.
