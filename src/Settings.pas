unit Settings;

interface

type
  TAppSettings = record
    ReceiverEmailsCsv: string;
    BackendBaseUrl: string;
    ApiKey: string;
    SenderEmail: string;
    SenderAppPassword: string;
    class function Default: TAppSettings; static;
  end;

implementation

class function TAppSettings.Default: TAppSettings;
begin
  Result.ReceiverEmailsCsv := '';
  Result.BackendBaseUrl := '';
  Result.ApiKey := '';
  Result.SenderEmail := '';
  Result.SenderAppPassword := '';
end;

end.
