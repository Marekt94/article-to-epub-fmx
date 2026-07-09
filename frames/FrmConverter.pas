unit FrmConverter;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, ClientInterface, Settings,
  ClientFactory, SettingsInterface, Classes;

type
  TFrame2 = class(TFrame, IExecutingHandlers)
    LayoutMain: TLayout;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    FClient: IClient;
    FOnStart: TProc;
    FOnFinish: TProc<string>;
    FOnError: TProc<TObject>;
    FSettingsRepo: ISettingsRepository;
    FIntentDetails: string;
    FOnOpenBrowser: TProc<string>;
  public
    procedure Init(const ARepo: ISettingsRepository);
    {$IF DEFINED(ANDROID)}
    procedure OnShareIntent;
    {$ENDIF}
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc<string>);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
    property OnOpenBrowser: TProc<string> write FOnOpenBrowser;
  end;

implementation

uses
  FMX.DialogService
  {$IF DEFINED(ANDROID)}
  , Androidapi.JNI.App
  , Androidapi.JNI.JavaTypes
  , Androidapi.Helpers
  , Androidapi.JNI.GraphicsContentViewText
  {$ENDIF}
  ;

{$R *.fmx}

procedure TFrame2.Button1Click(Sender: TObject);
begin
  var AppSettings := FSettingsRepo.Load;
  FClient := TClientFactory.CreateInstance(AppSettings);
  var temp: IExecutingHandlers;
  if Supports(FClient, IExecutingHandlers, temp) then
  begin
    temp.OnStart := FOnStart;
    temp.OnSuccess := FOnFinish;
    temp.OnError := FOnError;
  end;
  FClient.FetchURL(Edit1.Text.Trim, AppSettings.ReceiverEmailsCsv);
end;

procedure TFrame2.Button2Click(Sender: TObject);
begin
  if Edit1.Text.Trim = '' then
  begin
    TDialogService.MessageDialog('Podaj adres URL artyku'#322'u.',
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk, 0, nil);
    Exit;
  end;
  if Assigned(FOnOpenBrowser) then
    FOnOpenBrowser(Edit1.Text.Trim);
end;

procedure TFrame2.Init(const ARepo: ISettingsRepository);
begin
  FSettingsRepo := ARepo;
end;

{$IF DEFINED(ANDROID)}
procedure TFrame2.OnShareIntent;
var
  LIntent: JIntent;
  LAction, LText: string;
begin
  LIntent := TAndroidHelper.Activity.getIntent();
  if not Assigned(LIntent) then
    exit;

  LAction := JStringToString(LIntent.getAction);
  LText := JStringToString(LIntent.getStringExtra(TJIntent.JavaClass.EXTRA_TEXT));

  if LText = FIntentDetails then
    exit;

  if LAction = JStringToString(TJIntent.JavaClass.ACTION_SEND) then
  begin
    FIntentDetails := LText;
    Edit1.Text := LText;
  end;
end;
{$ENDIF}

procedure TFrame2.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

procedure TFrame2.SetOnSuccess(const AProc: TProc<string>);
begin
  FOnFinish := AProc;
end;

procedure TFrame2.SetOnStart(const AProc: TProc);
begin
  FOnStart := AProc;
end;

end.
