Unit IOptions;

interface

uses Drivers, Dialogs, Objects, Views, ITypes ;

type

  PDetectOptionsDialog = ^TDetectOptionsDialog;
  TDetectOptionsDialog = object(TDialog)
    DetectCheck: PCheckBoxes;
    WaitCheck: PCheckBoxes;
    CheckCheck: PCheckBoxes;
    OtherCheck: PCheckBoxes;
    constructor Init;

  end;


  PGeneralOptionsDialog = ^TGeneralOptionsDialog;
  TGeneralOptionsDialog = object(TDialog)
    DesktopCheck: PCheckBoxes;
    constructor Init;
  end;


  PProjectOptionsDialog = ^TProjectOptionsDialog;
  TProjectOptionsDialog = object(TDialog)
    constructor Init;
  end;




  PDirection = ^TDirection;
  TDirection = object(TRadioButtons)
  end;



  PReadOptionsDialog = ^TReadOptionsDialog;
  TReadOptionsDialog = object(TDialog)
    FStartSector: PInputLine;
    FEndSector: PInputLine;
    FDirection: PDirection;

    constructor Init;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;

  end;


implementation

uses IProject;

{ TDetectOptionsDialog }

constructor TDetectOptionsDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 54, 17);
  inherited Init(R, 'Detect options');
  Options := Options + ofCentered;

  R.Assign(3, 3, 25, 7);
  DetectCheck := New(PCheckBoxes, Init(R,
    NewSItem('Primary Master',
    NewSItem('Primary Slave',
    NewSItem('Secondary Master',
    NewSItem('Secondary Slave', nil))))));
  Insert(DetectCheck);

  R.Assign(2, 2, 20, 3);
  Control := New(PLabel, Init(R, '~D~etect drive', DetectCheck));
  Insert(Control);

  R.Assign(27, 3, 51, 8);
  WaitCheck := New(PCheckBoxes, Init(R,
    NewSItem('Primary Master',
    NewSItem('Primary Slave',
    NewSItem('Secondary Master',
    NewSItem('Secondary Slave',
    NewSItem('Any hard drive', nil)))))));
  WaitCheck^.EnableMask := 15;
  Insert(WaitCheck);

  R.Assign(26, 2, 51, 3);
  Control := New(PLabel, Init(R, '~T~ry until detected', WaitCheck));
  Insert(Control);

  R.Assign(3, 9, 25, 13);
  CheckCheck := New(PCheckBoxes, Init(R,
    NewSItem('Busy check',
    NewSItem('Hazard check',
    NewSItem('Ready check',
    NewSItem('Data check', nil))))));

  CheckCheck^.EnableMask := 7;

  Insert(CheckCheck);

  R.Assign(2, 8, 20, 9);
  Control := New(PLabel, Init(R, '~C~heck options', CheckCheck));
  Insert(Control);

  R.Assign(27, 10, 51, 13);
  OtherCheck := New(PCheckBoxes, Init(R,
    NewSItem('Beep when detected',
    NewSItem('Read when detected',
    nil))));
  OtherCheck^.EnableMask := 0;
  Insert(OtherCheck);

  R.Assign(26, 9, 51, 10);
  Control := New(PLabel, Init(R, '~O~ther options', OtherCheck));
  Insert(Control);

  R.Assign(30, 14, 40,  16);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(41, 14, 51, 16);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  DetectCheck^.Focus;
end;


{ TGeneralOptionsDialog }
constructor TGeneralOptionsDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 33, 11);
  inherited Init(R, 'General options');
  Options := Options + ofCentered;

  R.Assign(3, 3, 30, 7);
  DesktopCheck := New(PCheckBoxes, Init(R,
    NewSItem('Free memory',
    NewSItem('Clock',
    NewSItem('About at start',
    NewSItem('New project at start', nil))))));
  Insert(DesktopCheck);

  R.Assign(2, 2, 20, 3);
  Control := New(PLabel, Init(R, '~D~esktop', DesktopCheck));
  Insert(Control);


  R.Assign(9, 8, 19,  10);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(20, 8, 30, 10);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  DesktopCheck^.Focus;
end;


{ TProjectOptionsDialog }

constructor TProjectOptionsDialog.Init;
var
  R: TRect;
  Control: PView;
  FControl: PView;

begin
  R.Assign(0, 0, 49, 13);
  inherited Init(R, 'Project options');
  Options := Options + ofCentered;

  R.Assign(22, 2, 46, 3);
  FControl := New(PInputLine, Init(R, 80));
  Insert(FControl);

  R.Assign(2, 2, 22, 3);
  Control := New(PLabel, Init(R, '~P~rojects directory', FControl));
  Insert(Control);

  R.Assign(22, 4, 46, 5);
  Control := New(PInputLine, Init(R, 80));
  Insert(Control);

  R.Assign(2, 4, 22, 5);
  Control := New(PLabel, Init(R, '~I~mages directory', Control));
  Insert(Control);

  R.Assign(3, 6, 46, 8);
  Control := New(PCheckBoxes,
    Init(R,  NewSItem('~C~reate subdirectory for image files',
       NewSItem('~B~uffered write', nil))));
  PCluster(Control)^.EnableMask := 1;
  Insert(Control);

  R.Assign(25, 10, 35,  12);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(36, 10, 46, 12);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  FControl^.Focus;
end;




{ TReadOptionsDialog }

constructor TReadOptionsDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 34, 11);
  inherited Init(R, 'Read options');
  Options := Options + ofCentered;


  R.Assign(15, 2, 30, 4);
  FDirection := New(PDirection, Init(R,
    NewSItem('Forward',
    NewSItem('Backward', nil))));
  FDirection^.EnableMask := 1;
  Insert(FDirection);



  R.Assign(2, 2, 13, 3);
  Control := New(PLabel, Init(R, '~D~irection', FDirection));
  Insert(Control);


  R.Assign(18, 5, 30, 6);
  FStartSector := New(PInputLine, Init(R, 10));
  Insert(FStartSector);


  R.Assign(2, 5, 17, 6);
  Control := New(PLabel, Init(R, '~S~tart sector', FStartSector));
  Insert(Control);


  R.Assign(18, 6, 30, 7);
  FEndSector := New(PInputLine, Init(R, 10));
  Insert(FEndSector);


  R.Assign(2, 6, 17, 7);
  Control := New(PLabel, Init(R, '~E~nd sector', FEndSector));
  Insert(Control);


  R.Assign(20, 8, 30, 10);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  R.Assign(9, 8, 19, 10);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

end;

procedure TReadOptionsDialog.GetData(var Rec);
var
  e: Integer;

begin
  with TSectorsRec(Rec) do begin
    Val(FStartSector^.Data^, StartSector, e);
    Val(FEndSector^.Data^, EndSector, e);
  end;
end;


procedure TReadOptionsDialog.SetData(var Rec);
begin
  with TGeometryRec(Rec) do begin
    Str(AddressableSectors, FEndSector^.Data^);
    Str(0, FStartSector^.Data^);
  end;
end;

end.