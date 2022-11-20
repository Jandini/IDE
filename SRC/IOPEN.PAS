Unit IOpen;

interface

uses Objects, Views, Dialogs, Drivers, ITypes;

type
  POpenDialog = ^TOpenDialog;
  TOpenDialog = object(TDialog)
    Name: PInputLine;
    constructor Init(ATitle: String);
  end;


implementation

constructor TOpenDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 35, 7);

  Inherited Init(R, ATitle);
  Options := Options + ofCentered;

  R.Assign(11, 4, 21, 6);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(22, 4, 32, 6);
  Control := New(PButton, Init(R, 'Anuluj', cmCancel, bfNormal));
  Insert(Control);

  R.Assign(22, 2, 31, 3);
  Name := New(PInputLine, Init(R, 8));
  Insert(Name);

  R.Assign(2, 2, 22, 3);
  Control := New(PLabel, Init(R, 'Enter ~p~roject name', Name));
  Insert(Control);
end;



end.