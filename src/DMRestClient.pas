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

  TError = class;

  TRESTClient = class(TInterfacedObject, IClient, IExecutingHandlers)
  strict private
    FDM: TDataModule1;
    FAppSettings: TAppSettings;
    FOnStart: TProc;
    FOnSuccess: TProc<string>;
    FOnError: TProc<TObject>;
    procedure AddCommonHeaders(Areq: TCustomRESTRequest);
    function Error(const AResp: TRESTResponse; const ADefaultErrorText: string): string; overload;
  public
    constructor Create(const AAppSettings: TAppSettings);
    destructor Destroy; override;

    procedure FetchURL(const AURL: string; const AReceiverEmail: string);
    procedure Health;

    procedure Start;
    procedure Error(AObj: TObject); overload;

    procedure FinishFetchURL;
    procedure FinishHealth;

    procedure ErrorFetchUrl(AObj: TObject);

    function IsSuccess(const AResp: TRESTResponse; out AInfo: string): boolean;

    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc<string>);
    procedure SetOnError(const AError: TProc<TObject>);
  end;

  TBody = class
  private
    [JSONName('url')]
    FUrl: string;
    [JSONName('email')]
    FEmails: TArray<string>;
  end;

  TError = class
    private
    [JSONName('error')]
    FError: string;
  end;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TRESTClient }

const
  cGenericError = '%d: %s';
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

function TRESTClient.Error(const AResp: TRESTResponse; const ADefaultErrorText: string): string;
begin
  var error := TJson.JsonToObject<TError>(AResp.Content);
  if Assigned(error) then
    result := Format(cGenericError, [AResp.StatusCode, error.FError])
  else
    Result := ADefaultErrorText
end;

procedure TRESTClient.ErrorFetchUrl(AObj: TObject);
begin
  TThread.Synchronize(nil, procedure
    begin
      var err := Exception(AObj);
      if Assigned(FOnError) then
      begin
        var resErrorText := Error(FDm.FetchURLWithSendResp, err.Message);
        FOnError(Exception.Create(resErrorText))
      end;
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
    FDM.RRFetchURLWithSend.ExecuteAsync(FinishFetchURL, false, true, ErrorFetchUrl);
  finally
    req.Free;
  end;
end;

procedure TRESTClient.FinishHealth;
begin
  TThread.Synchronize(nil, procedure
    begin
      var info: string;
      if IsSuccess(FDM.HelthResp, info) then
      begin
        if Assigned(FOnSuccess) then
          FOnSuccess('Po³¹czono z serwerem')
      end
      else if Assigned(FOnError) then
        FOnError(Exception.Create(info));
    end);
end;

procedure TRESTClient.FinishFetchURL;
begin
  TThread.Synchronize(nil, procedure
    begin
      var info: string;
      if IsSuccess(FDM.FetchURLWithSendResp, info) then
      begin
        if Assigned(FOnSuccess) then
          FOnSuccess('Artyku³ skonwertowany i wys³any poprawnie')
      end
      else if Assigned(FOnError) then
        FOnError(Exception.Create(info))
    end);
end;

procedure TRESTClient.Health;
begin
  Start;
  FDM.RRHealth.ExecuteAsync(FinishHealth, false, true, Error);
end;

function TRESTClient.IsSuccess(const AResp: TRESTResponse;
  out AInfo: string): boolean;
var
  jsonText: string;
begin
  case AResp.StatusCode of
    200..299:
    begin
      Result := true;
      AInfo := '';
    end;
  else
    Result := False;
    AInfo := Format(cGenericError, [AResp.StatusCode, AResp.StatusText]);
  end;
end;

procedure TRESTClient.SetOnError(const AError: TProc<TObject>);
begin
  FOnError := AError;
end;

procedure TRESTClient.SetOnSuccess(const AProc: TProc<string>);
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
