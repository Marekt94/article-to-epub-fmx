unit FmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Variants,
  System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.DialogService, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, System.ImageList, FMX.ImgList,
  FMX.TabControl, SettingsRepository, FMX.Ani, FMX.Gestures, SettingsInterface, FrmConverter,
  FrmSettings, FrmBrowser, ClientInterface, FMX.Platform, Classes;

type
  TForm1 = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    ImageList1: TImageList;
    FfrmSettings: TFrame1;
    FfrmConverter: TFrame2;
    FfrmBrowser: TFrame3;
    AniIndicator1: TAniIndicator;
    procedure FormCreate(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure FfrmConverterButton2Click(Sender: TObject);
  private
    { Private declarations }
    FSettingsRepo: ISettingsRepository;
    procedure OpenBrowser(AUrl: string);
    procedure CloseBrowser;
    procedure ShowConverterTab;
    {$IF DEFINED(ANDROID)}
    function AppEventHanlder(AAppEvent: TApplicationEvent; AContext: TObject): boolean;
    {$ENDIF}
  public
    procedure Init;
    procedure OnStart;
    procedure OnFinish;
    procedure OnError(AObj: TObject);
    procedure OnSuccess(AText: string);
  end;

implementation

uses
  FMX.Dialogs;

{$R *.fmx}
{$R *.Windows.fmx MSWINDOWS}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.Surface.fmx MSWINDOWS}

{$IF DEFINED(ANDROID)}
function TForm1.AppEventHanlder(AAppEvent: TApplicationEvent;
  AContext: TObject): boolean;
begin
  if AAppEvent = TApplicationEvent.BecameActive then
    FfrmConverter.OnShareIntent;
  result := true;
end;
{$ENDIF}

procedure TForm1.FfrmConverterButton2Click(Sender: TObject);
begin
  FfrmConverter.Button2Click(Sender);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Init;
end;

procedure TForm1.Init;
var
  temp: IExecutingHandlers;
begin
  for var comp in [TFrame(FfrmSettings), TFrame(FfrmConverter), TFrame(FfrmBrowser)] do
  begin
    if Supports(comp, IExecutingHandlers, temp) then
    begin
      temp.OnStart := OnStart;
      temp.OnSuccess := OnSuccess;
      temp.OnError := OnError;
    end;
  end;

  FSettingsRepo := TIniFileSettingsRepository.Create;
  FfrmSettings.Init(FSettingsRepo);
  FfrmConverter.Init(FSettingsRepo);
  FfrmBrowser.Init(FSettingsRepo);
  FfrmConverter.OnOpenBrowser := OpenBrowser;
  FfrmConverter.OnShareReceived := ShowConverterTab;
  FfrmBrowser.OnClose := CloseBrowser;

{$IF DEFINED(ANDROID)}
  var appEventSvc: IFMXApplicationEventService;
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(appEventSvc)) then
    appEventSvc.SetApplicationEventHandler(AppEventHanlder);
{$ENDIF}
end;

procedure TForm1.OnError(AObj: TObject);
begin
  OnFinish;
  if not Assigned(AObj) then
  begin
    TDialogService.MessageDialog('Error object is nil', TMsgDlgType.mtError, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil);
    Exit;
  end;

  if AObj is Exception then
    TDialogService.MessageDialog(Exception(AObj).Message, TMsgDlgType.mtError, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil)
  else
    TDialogService.MessageDialog('Unknown exception', TMsgDlgType.mtError, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil)
end;

procedure TForm1.OnFinish;
begin
  AniIndicator1.Visible := False;
  AniIndicator1.Enabled := False;
  TabControl1.Opacity := 1;
end;

procedure TForm1.OnStart;
begin
  AniIndicator1.Visible := true;
  AniIndicator1.Enabled := True;
  TabControl1.Opacity := 0.3;
end;

procedure TForm1.OnSuccess(AText: string);
var
 LText: string;
begin
  OnFinish;
  if AText.Trim = '' then
    LText := 'Task finished successfully'
  else
    LText := AText;
  TDialogService.MessageDialog(LText, TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil)
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  if TabControl1.ActiveTab <> TabItem2 then
    FfrmSettings.SaveToRepo
end;

procedure TForm1.OpenBrowser(AUrl: string);
begin
  TabItem3.Visible := True;
  // Ukrywamy caly pasek zakladek na czas przegladania, zeby nie pokazywala sie
  // dodatkowa zakladka na dole. Przywracamy go w CloseBrowser.
  TabControl1.TabPosition := TTabPosition.None;
  TabControl1.ActiveTab := TabItem3;
  FfrmBrowser.OpenUrl(AUrl);
end;

procedure TForm1.CloseBrowser;
begin
  TabControl1.ActiveTab := TabItem1;
  TabControl1.TabPosition := TTabPosition.Bottom;
  TabItem3.Visible := False;
end;

procedure TForm1.ShowConverterTab;
begin
  // Nowy URL z Udostepnij: jesli byla otwarta przegladarka, zamykamy ja i wracamy
  // do konwertera; w przeciwnym razie po prostu przechodzimy na zakladke konwertera.
  if TabItem3.Visible then
    CloseBrowser
  else
    TabControl1.ActiveTab := TabItem1;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
begin
  if ((Key = vkHardwareBack) or (Key = vkEscape)) and (TabControl1.ActiveTab = TabItem3) then
  begin
    Key := 0;
    // Wstecz (gest / przycisk) zawsze wraca do glownego menu,
    // nie cofa historii przegladarki.
    CloseBrowser;
  end;
end;

end.
