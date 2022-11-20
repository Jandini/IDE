Unit IAbout;

interface

uses Dialogs, Objects, Views;

type

  PAboutDialog = ^TAboutDialog;
  TAboutDialog = object(TDialog)
     constructor Init;
  end;

implementation


{ TAboutDialog }

constructor TAboutDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 36, 15);
  inherited Init(R, 'About');
  Options := Options + ofCentered;

  R.Assign(1, 2, 35, 11);
  Control := New(PStaticText,
    Init(R, #3'IDE for Data Recovery' +
      #13#13#3'Version 2.01' +
      #13#13#3'Copyright (c) 2001,02 by' +
      #13#13#3'Mateusz Janda' +
      #13#13#3'mat@elzab.com.pl'));

  Insert(Control);
  R.Assign(13, 12, 23, 14);
  Control := New(PButton, Init(R, '~O~K', cmOK, bfDefault));
  Insert(Control);
end;


end.