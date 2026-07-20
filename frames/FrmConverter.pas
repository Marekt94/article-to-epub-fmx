unit FrmConverter;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, ClientInterface, Settings,
  ClientFactory, SettingsInterface, Classes
  {$IF DEFINED(ANDROID)}
  , System.Messaging, Androidapi.JNI.GraphicsContentViewText
  {$ENDIF};

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
    {$IF DEFINED(ANDROID)}
    FIntentDetails: string;
    FShareSubID: Integer;
    {$ENDIF}
    FOnOpenBrowser: TProc<string>;
    FOnShareReceived: TProc;
    {$IF DEFINED(ANDROID)}
    procedure ProcessShareIntent(const AIntent: JIntent; ADedup: Boolean);
    procedure NewIntentListener(const Sender: TObject; const M: TMessage);
    {$ENDIF}
  public
    destructor Destroy; override;
    procedure Init(const ARepo: ISettingsRepository);
    {$IF DEFINED(ANDROID)}
    procedure OnShareIntent;
    {$ENDIF}
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc<string>);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
    property OnOpenBrowser: TProc<string> write FOnOpenBrowser;
    // Wywolywane, gdy przez Udostepnij przyjdzie nowy URL - host przelacza sie
    // wtedy na zakladke konwertera (a nie zostaje w przegladarce).
    property OnShareReceived: TProc write FOnShareReceived;
  end;

implementation

uses
  FMX.DialogService
  {$IF DEFINED(ANDROID)}
  , Androidapi.JNI.App
  , Androidapi.JNI.JavaTypes
  , Androidapi.Helpers
  , Androidapi.JNI.Embarcadero
  , Androidapi.JNIBridge
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
  {$IF DEFINED(ANDROID)}
  // FMX rozglasza TMessageReceivedNotification z onNewIntent TYLKO dla akcji wczesniej
  // zarejestrowanych (domyslnie same powiadomienia - patrz FMXNativeActivity.java).
  // Rejestrujemy ACTION_SEND, aby dostawac swieze intenty udostepniania, gdy aplikacja
  // juz dziala (cieply start: singleTop -> onNewIntent).
  TJFMXNativeActivity.Wrap((TAndroidHelper.Activity as ILocalObject).GetObjectID)
    .registerIntentAction(TJIntent.JavaClass.ACTION_SEND);
  // Cieply start: swiezy intent przychodzi przez onNewIntent i jest rozglaszany jako
  // TMessageReceivedNotification (NewIntentListener). Zimny start obsluguje OnShareIntent.
  FShareSubID := TMessageManager.DefaultManager.SubscribeToMessage(
    TMessageReceivedNotification, NewIntentListener);
  {$ENDIF}
end;

destructor TFrame2.Destroy;
begin
  {$IF DEFINED(ANDROID)}
  if FShareSubID <> 0 then
    TMessageManager.DefaultManager.Unsubscribe(TMessageReceivedNotification, FShareSubID);
  {$ENDIF}
  inherited;
end;

{$IF DEFINED(ANDROID)}
procedure TFrame2.ProcessShareIntent(const AIntent: JIntent; ADedup: Boolean);
var
  LAction, LText: string;
begin
  if not Assigned(AIntent) then
    exit;

  LAction := JStringToString(AIntent.getAction);
  LText := JStringToString(AIntent.getStringExtra(TJIntent.JavaClass.EXTRA_TEXT));

  // Deduplikacja tylko dla sciezki getIntent (BecameActive): zwykle wznowienie
  // (np. powrot z potwierdzenia logowania) niesie wciaz ten sam intent startowy,
  // wiec nie ruszamy pola URL. Dla onNewIntent (realne, swieze udostepnienie)
  // stosujemy zawsze - nawet gdy URL jest taki sam jak poprzednio udostepniony.
  if ADedup and (LText = FIntentDetails) then
    exit;

  if LAction = JStringToString(TJIntent.JavaClass.ACTION_SEND) then
  begin
    FIntentDetails := LText;
    Edit1.Text := LText;
    if Assigned(FOnShareReceived) then
      FOnShareReceived;
  end;
end;

procedure TFrame2.OnShareIntent;
begin
  // Zimny start / odtworzenie activity: intent startowy jest swiezy w getIntent(),
  // ale przy kazdym kolejnym wznowieniu getIntent zwraca ten sam intent -> dedup.
  ProcessShareIntent(TAndroidHelper.Activity.getIntent, True);
end;

procedure TFrame2.NewIntentListener(const Sender: TObject; const M: TMessage);
var
  LIntent: JIntent;
begin
  // Cieply start (singleTop -> onNewIntent). getIntent() zwraca tu STARY intent, wiec
  // najpierw aktualizujemy intent activity (setIntent), potem przetwarzamy swiezy.
  if not (M is TMessageReceivedNotification) then
    exit;
  LIntent := TMessageReceivedNotification(M).Value;
  if not Assigned(LIntent) then
    exit;
  TAndroidHelper.Activity.setIntent(LIntent);
  // onNewIntent = realne, swieze udostepnienie -> bez dedup (nawet ten sam URL).
  ProcessShareIntent(LIntent, False);
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
