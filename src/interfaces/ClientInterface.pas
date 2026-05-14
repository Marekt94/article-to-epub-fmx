unit ClientInterface;

interface

uses
  SysUtils;

type
  IClient = interface(IInterface)
    ['{CBBF9AD4-600E-4E0C-8539-CF06AA7DF296}']
    procedure FetchURL(const AURL: string; const AReceiverEmail: string);
    procedure Health(const AOnDone: TProc<boolean>);
  end;

  IExecutingHandlers = interface(IInterface)
  ['{7B992F13-AE62-44EF-84E0-17673351FFAB}']
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnFinish(const AProc: TProc);
    property OnStart: TProc write SetOnStart;
    property OnFinish: TProc write SetOnFinish;
  end;

implementation

end.
