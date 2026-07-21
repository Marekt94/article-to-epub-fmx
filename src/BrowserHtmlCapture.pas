unit BrowserHtmlCapture;

interface

uses
  System.SysUtils, FMX.WebBrowser;

type
  THtmlCaptureCallback = reference to procedure(const AHtml, AError: string);

const
  // Komunikat, gdy brak silnika przegladarki (Windows: brak WebView2 Runtime / loadera).
  SBrowserEngineUnavailable =
    'Wbudowana przegl'#261'darka wymaga silnika Edge (WebView2). ' +
    'Sprawd'#378', czy zainstalowano WebView2 Runtime i czy WebView2Loader.dll ' +
    'znajduje si'#281' obok pliku EXE.';

// Zwraca True, gdy natywny silnik przegladarki jest dostepny (Android: zawsze).
function BrowserEngineAvailable: Boolean;

// Zwraca aktualny URL strony w przegladarce (pusty string, gdy niedostepny).
// Czytany z natywnego silnika - WebBrowser.URL (FMX) nie aktualizuje sie przy
// nawigacji uzytkownika i zwraca poczatkowe about:blank.
function GetCurrentUrl(const AWebBrowser: TCustomWebBrowser): string;

// Pobiera HTML aktualnie wyswietlanej strony (document.documentElement.outerHTML)
// z natywnej przegladarki. Callback jest wywolywany dokladnie raz, na watku UI;
// przy bledzie AError <> ''.
procedure CaptureHtml(const AWebBrowser: TCustomWebBrowser;
  const ACallback: THtmlCaptureCallback);

// Ustawia User-Agent natywnego silnika na "czyste" Chrome (bez markera ";wv"),
// aby logowanie Google (OAuth) nie bylo blokowane w osadzonej przegladarce.
// Wywolywac przed Navigate. Dziala best-effort - jesli natywny silnik nie jest
// jeszcze gotowy, nic nie robi (zostaje domyslny User-Agent).
procedure ConfigureUserAgent(const AWebBrowser: TCustomWebBrowser);

// Usuwa dane logowania wbudowanej przegladarki: pliki cookie oraz dane stron (localStorage,
// IndexedDB itp.). Android uzywa globalnych menedzerow (CookieManager, WebStorage), wiec nie
// wymaga instancji WebView - moze byc wolane z dowolnego miejsca (np. z ramki Ustawien).
// Efektywnie wylogowuje ze wszystkich stron otwieranych w aplikacji (m.in. Google/onet).
// Zwraca True przy powodzeniu; przy bledzie False i AError zawiera opis. Windows: brak wsparcia.
function ClearBrowserData(out AError: string): Boolean;

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
  , Winapi.ActiveX
  , Winapi.WebView2
  , Winapi.EdgeUtils
{$ENDIF};

const
  cCaptureScript = 'document.documentElement.outerHTML';
  sHtmlDecodeError = 'Nie uda'#322'o si'#281' pobra'#263' kodu HTML strony.';
  // "Czysty" User-Agent Chrome (bez markera ";wv"), aby Google nie blokowal OAuth
  // w osadzonym WebView (blad disallowed_useragent). Aktualizowac wersje Chrome co jakis czas.
  cAndroidUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';
  cWindowsUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

function BrowserEngineAvailable: Boolean;
begin
{$IF DEFINED(ANDROID)}
  Result := True;
{$ELSEIF DEFINED(MSWINDOWS)}
  // IsEdgeAvailable robi tylko LoadLibrary + sprawdzenie OS (nie wola procedur z DLL),
  // wiec jest bezpieczne. NIE uzywac GetCoreWebView2BrowserVersionString - EdgeUtils
  // wiaze je pod zla nazwa eksportu (brak w WebView2Loader.dll) => nil ptr => AV.
  Result := IsEdgeAvailable;
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure ConfigureUserAgent(const AWebBrowser: TCustomWebBrowser);
{$IF DEFINED(ANDROID)}
var
  LWebView: JWebBrowser;
begin
  // Ten sam cast co w GetCurrentUrl/CaptureHtml: FMX przekazuje IID do natywnego WebView.
  if Supports(AWebBrowser, JWebBrowser, LWebView) and (LWebView.getSettings <> nil) then
  begin
    LWebView.getSettings.setUserAgentString(StringToJString(cAndroidUserAgent));
    // Wiele logowan (w tym Google) wymaga localStorage do dzialania.
    LWebView.getSettings.setDomStorageEnabled(True);
  end;
end;
{$ELSEIF DEFINED(MSWINDOWS)}
var
  LWebView: ICoreWebView2;
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2;
begin
  // Domyslny User-Agent WebView2 to juz Edge/Chromium (Google zwykle go akceptuje),
  // wiec to zabezpieczenie na przyszlosc. put_UserAgent jest na ICoreWebView2Settings2.
  if Supports(AWebBrowser, ICoreWebView2, LWebView)
    and (LWebView.Get_Settings(LSettings) = S_OK)
    and Supports(LSettings, ICoreWebView2Settings2, LSettings2) then
    LSettings2.Set_UserAgent(PWideChar(cWindowsUserAgent));
end;
{$ELSE}
begin
end;
{$ENDIF}

function ClearBrowserData(out AError: string): Boolean;
{$IF DEFINED(ANDROID)}
begin
  AError := '';
  try
    // removeAllCookies akceptuje null jako callback (nie potrzebujemy powiadomienia).
    // flush wymusza natychmiastowy zapis pustego magazynu cookies na dysk.
    TJCookieManager.JavaClass.getInstance.removeAllCookies(nil);
    TJCookieManager.JavaClass.getInstance.flush;
    // Dane stron (localStorage/IndexedDB) - logowanie Google z nich korzysta.
    TJWebStorage.JavaClass.getInstance.deleteAllData;
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;
{$ELSE}
begin
  AError := 'Czyszczenie danych przegl'#261'darki jest dost'#281'pne tylko na Androidzie.';
  Result := False;
end;
{$ENDIF}

function GetCurrentUrl(const AWebBrowser: TCustomWebBrowser): string;
{$IF DEFINED(ANDROID)}
var
  LWebView: JWebBrowser;
begin
  Result := '';
  if Supports(AWebBrowser, JWebBrowser, LWebView) and (LWebView.getUrl <> nil) then
    Result := JStringToString(LWebView.getUrl);
end;
{$ELSEIF DEFINED(MSWINDOWS)}
var
  LWebView: ICoreWebView2;
  LUri: PWideChar;
begin
  Result := '';
  if Supports(AWebBrowser, ICoreWebView2, LWebView) then
  begin
    LUri := nil;
    if (LWebView.Get_Source(LUri) = S_OK) and (LUri <> nil) then
    begin
      Result := string(LUri);
      CoTaskMemFree(LUri);
    end;
  end;
end;
{$ELSE}
begin
  Result := '';
end;
{$ENDIF}

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
    ACallback('', SBrowserEngineUnavailable);
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
