unit FmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, System.ImageList, FMX.ImgList,
  FMX.TabControl, SettingsRepository, FMX.Ani, FMX.Gestures, SettingsInterface, FrmConverter,
  FrmSettings, ClientInterface;

type
  TForm1 = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    ImageList1: TImageList;
    FfrmSettings: TFrame1;
    FfrmConverter: TFrame2;
    AniIndicator1: TAniIndicator;
    procedure FormCreate(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
  private
    { Private declarations }
    FSettingsRepo: ISettingsRepository;
  public
    procedure Init;
    procedure OnStart;
    procedure OnFinish;
  end;

implementation

{$R *.fmx}
{$R *.Windows.fmx MSWINDOWS}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.Surface.fmx MSWINDOWS}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Init;
end;

procedure TForm1.Init;
var
  temp: IExecutingHandlers;
begin
  for var comp in [FfrmSettings, FfrmConverter] do
  begin
    if Supports(comp, IExecutingHandlers, temp) then
    begin
      temp.OnStart := OnStart;
      temp.OnFinish := OnFinish
    end;
  end;

  FSettingsRepo := TIniFileSettingsRepository.Create;
  FfrmSettings.Init(FSettingsRepo);
  FfrmConverter.Init(FSettingsRepo);
end;

procedure TForm1.OnFinish;
begin
  AniIndicator1.Visible := False;
  AniIndicator1.Enabled := False;
  TabControl1.Opacity := 1;
end;

procedure TForm1.OnStart;
begin
  AniIndicator1.Visible := true;
  AniIndicator1.Enabled := True;
  TabControl1.Opacity := 0.3;
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  if TabControl1.ActiveTab <> TabItem2 then
    FfrmSettings.SaveToRepo
end;

end.
