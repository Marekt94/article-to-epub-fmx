unit SettingsInterface;

interface

uses
  Settings;

type
  ISettingsRepository = interface
    ['{9E9A6F64-2F6D-4D7E-8B0B-96C6D5A6A7B1}']
    function Load: TAppSettings;
    procedure Save(const ASettings: TAppSettings);
  end;

implementation

end.
