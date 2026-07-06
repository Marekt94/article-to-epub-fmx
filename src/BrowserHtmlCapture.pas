unit BrowserHtmlCapture;

interface

uses
  System.SysUtils, FMX.WebBrowser;

type
  THtmlCaptureCallback = reference to procedure(const AHtml, AError: string);

// Pobiera HTML aktualnie wyswietlanej strony (document.documentElement.outerHTML)
// z natywnej przegladarki. Callback jest wywolywany dokladnie raz, na watku UI;
// przy bledzie AError <> ''.
procedure CaptureHtml(const AWebBrowser: TCustomWebBrowser;
  const ACallback: THtmlCaptureCallback);

implementation

uses
  System.Classes, System.JSON
{$IF DEFINED(ANDROID)}
  , Androidapi.JNIBridge
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.Webkit
  , Androidapi.JNI.Embarcadero
  , Androidapi.Helpers
{$ELSEIF DEFINED(MSWINDOWS)}
  , Winapi.Windows
  , Winapi.WebView2
  , Winapi.EdgeUtils
{$ENDIF};

const
  cCaptureScript = 'document.documentElement.outerHTML';
  sHtmlDecodeError = 'Nie uda'#322'o si'#281' pobra'#263' kodu HTML strony.';

// Wynik skryptu przychodzi zakodowany jako JSON-owy literal stringa.
function DecodeJsonString(const AJson: string; out AValue: string): Boolean;
begin
  Result := False;
  AValue := '';
  var LVal := TJSONObject.ParseJSONValue(AJson);
  try
    if LVal is TJSONString then
    begin
      AValue := TJSONString(LVal).Value;
      Result := AValue <> '';
    end;
  finally
    LVal.Free;
  end;
end;

{$IF DEFINED(ANDROID)}
type
  THtmlValueCallback = class(TJavaLocal, JValueCallback)
  private
    FCallback: THtmlCaptureCallback;
  public
    constructor Create(const ACallback: THtmlCaptureCallback);
    procedure onReceiveValue(value: JObject); cdecl;
  end;

var
  // Utrzymuje proxy Java + obiekt Delphi przy zyciu do momentu wywolania callbacka.
  GPending: JValueCallback;

constructor THtmlValueCallback.Create(const ACallback: THtmlCaptureCallback);
begin
  inherited Create;
  FCallback := ACallback;
end;

procedure THtmlValueCallback.onReceiveValue(value: JObject);
var
  LHtml, LErr: string;
begin
  if value = nil then
    LErr := 'Strona nie zwr'#243'ci'#322'a tre'#347'ci.'
  else if not DecodeJsonString(JStringToString(value.toString), LHtml) then
    LErr := sHtmlDecodeError;
  var LCb := FCallback;
  TThread.Queue(nil,
    procedure
    begin
      GPending := nil;
      LCb(LHtml, LErr);
    end);
end;

procedure CaptureHtml(const AWebBrowser: TCustomWebBrowser;
  const ACallback: THtmlCaptureCallback);
var
  LWebView: JWebBrowser;
begin
  // QueryInterface kontrolki FMX przekazuje nieznane IID do natywnego WebView
  // (TCustomWebBrowser -> TAndroidWebBrowserService -> FWebView).
  if not Supports(AWebBrowser, JWebBrowser, LWebView) then
  begin
    ACallback('', 'Nie uda'#322'o si'#281' uzyska'#263' dost'#281'pu do wbudowanej przegl'#261'darki.');
    Exit;
  end;
  var LJavaCallback := THtmlValueCallback.Create(ACallback);
  GPending := LJavaCallback;
  LWebView.evaluateJavascript(StringToJString(cCaptureScript), LJavaCallback);
end;

{$ELSEIF DEFINED(MSWINDOWS)}
procedure CaptureHtml(const AWebBrowser: TCustomWebBrowser;
  const ACallback: THtmlCaptureCallback);
var
  LWebView: ICoreWebView2;
begin
  // Dziala tylko z silnikiem Edge (WindowsEngine = EdgeIfAvailable + WebView2Loader.dll).
  if not Supports(AWebBrowser, ICoreWebView2, LWebView) then
  begin
    ACallback('', 'Przechwycenie strony wymaga silnika Edge (WebView2). ' +
      'Sprawd'#378', czy WebView2Loader.dll znajduje si'#281' obok pliku EXE.');
    Exit;
  end;
  LWebView.ExecuteScript(PWideChar(cCaptureScript),
    Callback<HResult, PWideChar>.CreateAs<ICoreWebView2ExecuteScriptCompletedHandler>(
      function(AErrorCode: HResult; AResultJson: PWideChar): HResult stdcall
      var
        LHtml: string;
      begin
        Result := S_OK;
        if AErrorCode <> S_OK then
          ACallback('', Format('B'#322#261'd przegl'#261'darki WebView2 (0x%x).', [AErrorCode]))
        else if DecodeJsonString(string(AResultJson), LHtml) then
          ACallback(LHtml, '')
        else
          ACallback('', sHtmlDecodeError);
      end));
end;

{$ELSE}
procedure CaptureHtml(const AWebBrowser: TCustomWebBrowser;
  const ACallback: THtmlCaptureCallback);
begin
  ACallback('', 'Ta funkcja nie jest dost'#281'pna na tej platformie.');
end;
{$ENDIF}

end.
