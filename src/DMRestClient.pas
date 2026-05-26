unit DMRestClient;

interface

uses
  System.SysUtils, System.Classes, REST.Types, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, ClientInterface, Settings, FMX.Forms,
  REST.Json, REST.Json.Types;

type
  TDataModule1 = class(TDataModule)
    RESTClient1: TRESTClient;
    RRHealth: TRESTRequest;
    RRFetchURLWithEpubInResp: TRESTRequest;
    FetchURLWithEpubInResp: TRESTResponse;
    RRFetchURLWithSend: TRESTRequest;
    FetchURLWithSendResp: TRESTResponse;
    HelthResp: TRESTResponse;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TRESTClient = class(TInterfacedObject, IClient, IExecutingHandlers)
  strict private
    FDM: TDataModule1;
    FAppSettings: TAppSettings;
    FOnStart: TProc;
    FOnSuccess: TProc;
    FOnError: TProc<TObject>;
    procedure AddCommonHeaders(Areq: TCustomRESTRequest);
  public
    constructor Create(const AAppSettings: TAppSettings);
    destructor Destroy; override;

    procedure FetchURL(const AURL: string; const AReceiverEmail: string);
    procedure Health;

    procedure Start;
    procedure Finish;
    procedure Error(AObj: TObject);

    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
  end;

  TBody = class
  private
    [JSONName('url')]
    FUrl: string;
    [JSONName('email')]
    FEmails: TArray<string>;
  end;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TRESTClient }

const
  cAPIKey = 'API-Key %s';

procedure TRESTClient.AddCommonHeaders(Areq: TCustomRESTRequest);
begin
  Areq.Params.AddHeader('Authorization', Format(cAPIKey, [FAppSettings.ApiKey])).Options := [poDoNotEncode];
end;

constructor TRESTClient.Create(const AAppSettings: TAppSettings);
begin
  inherited Create;
  FAppSettings := AAppSettings;
  FDM := TDataModule1.Create(nil);
  FDM.RESTClient1.BaseURL := FAppSettings.BackendBaseUrl;

  FDM.RRFetchURLWithEpubInResp.OnBeforeExecute := AddCommonHeaders;
  FDM.RRFetchURLWithSend.OnBeforeExecute := AddCommonHeaders;
end;

destructor TRESTClient.Destroy;
begin
  FDM.Free;
  inherited;
end;

procedure TRESTClient.Error(AObj: TObject);
begin
  TThread.Synchronize(nil, procedure
    begin
      if Assigned(FOnError) then
        FOnError(AObj);
    end);
end;

procedure TRESTClient.FetchURL(const AURL, AReceiverEmail: string);
begin
  Start;
  var req := TBody.Create;
  try
    req.FUrl := AUrl;
    req.FEmails := AReceiverEmail.Split([',']);
    var reqStr := TJson.ObjectToJsonString(req);
    FDM.RRFetchURLWithSend.Params.AddItem(sBody, reqStr, pkREQUESTBODY, [], CONTENTTYPE_APPLICATION_JSON);
    FDM.RRFetchURLWithSend.ExecuteAsync(Finish, false, true, Error);
  finally
    req.Free;
  end;
end;

procedure TRESTClient.Finish;
begin
  TThread.Synchronize(nil, procedure
    begin
      if Assigned(FOnSuccess) then
        FOnSuccess;
    end);
end;

procedure TRESTClient.Health;
begin
  Start;
  FDM.RRHealth.ExecuteAsync(Finish, false, true, Error);
end;

procedure TRESTClient.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

procedure TRESTClient.SetOnSuccess(const AProc: TProc);
begin
  FOnSuccess := AProc;
end;

procedure TRESTClient.SetOnStart(const AProc: TProc);
begin
  FOnStart := AProc;
end;

procedure TRESTClient.Start;
begin
  TThread.Synchronize(nil, procedure
    begin
      if Assigned(FOnStart) then
        FOnStart;
    end);
end;

end.
