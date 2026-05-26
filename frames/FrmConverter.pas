unit FrmConverter;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, ClientInterface, Settings, ClientFactory,
  SettingsInterface;

type
  TFrame2 = class(TFrame, IExecutingHandlers)
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
  private
    FClient: IClient;
    FOnStart: TProc;
    FOnFinish: TProc;
    FOnError: TProc<TObject>;
    FSettingsRepo: ISettingsRepository;
  public
    procedure Init(const ARepo: ISettingsRepository);
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
  end;

implementation

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

procedure TFrame2.Init(const ARepo: ISettingsRepository);
begin
  FSettingsRepo := ARepo;
end;

procedure TFrame2.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

procedure TFrame2.SetOnSuccess(const AProc: TProc);
begin
  FOnFinish := AProc;
end;

procedure TFrame2.SetOnStart(const AProc: TProc);
begin
  FOnStart := AProc;
end;

end.
