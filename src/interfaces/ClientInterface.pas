unit ClientInterface;

interface

uses
  SysUtils;

type
  IClient = interface(IInterface)
    ['{CBBF9AD4-600E-4E0C-8539-CF06AA7DF296}']
    procedure FetchURL(const AURL: string; const AReceiverEmail: string);
    procedure Health;
  end;

  IExecutingHandlers = interface(IInterface)
  ['{7B992F13-AE62-44EF-84E0-17673351FFAB}']
    procedure SetOnStart(const AProc: TProc);
    procedure SetOnSuccess(const AProc: TProc);
    procedure SetOnError(const AError: TProc<TObject>);
    property OnStart: TProc write SetOnStart;
    property OnSuccess: TProc write SetOnSuccess;
    property OnError: TProc<TObject> write SetOnError;
  end;

implementation

end.
