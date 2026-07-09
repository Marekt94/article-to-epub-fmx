unit ClientFactory;

interface

uses
  Settings, ClientInterface;

type
  TClientFactory = class(TObject)
    class function CreateInstance(const AAppSettings: TAppSettings): IClient;
  end;

implementation

uses
  DMRestClient;

{ TClientFactory }

class function TClientFactory.CreateInstance(
  const AAppSettings: TAppSettings): IClient;
begin
  Result := TRESTClient.Create(AAppSettings);
end;

end.
