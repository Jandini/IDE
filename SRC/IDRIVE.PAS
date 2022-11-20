unit IDrive;

interface

uses Dialogs, Objects, Views, Drivers, IStream, ITypes, IProcs, IConst, IDetect, IConfig;

type

  PDriveList = ^TDriveList;
  TDriveList = object(TListBox)
    Strings: PCollection;

    constructor Init(R: TRect; ACol: Integer; ScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure InsertItem(s: String);
    procedure DeleteItem(index: Integer);
    procedure Clear;
  end;


  PDrivesInfo = ^TDrivesInfo;
  TDrivesInfo = object(TView)
    procedure Draw; virtual;
  end;


  PDriveDialog = ^TDriveDialog;
  TDriveDialog = object(TDialog)
    FCurrentDrive: Integer;
    FDriveCount: Byte;
    FDrives: Array[0..3] of TDriveInfo;

    FDetectOptions: TDetectOptionsRec;
    DriveList: PDriveList;
    DetectDrives: PDetectDrives;
    DrivesInfo: PDrivesInfo;

    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure GetData(var Rec); virtual;

    procedure OptionsDialog;
    procedure Detect;
  end;


  PSelectDriveDialog = ^TSelectDriveDialog;
  TSelectDriveDialog = object(TDialog)
    DriveCheck: PRadioButtons;
    constructor Init;

    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;

  end;

implementation

uses IOptions, ICmd, App, IProject, MsgBox;

{ TDriveList }

constructor TDriveList.Init(R: TRect; ACol: Integer; ScrollBar: PScrollBar);
begin
  inherited Init(R, ACol, ScrollBar);
  Options := Options or ofPostProcess;

  Strings := New(PCollection, Init(4, 1));
  NewList(Strings);
end;

destructor TDriveList.Done;
begin
  while List^.Count > 0 do begin
    DisposeStr(List^.Items^[0]);
    List^.Delete(List^.Items^[0]);
  end;
  Dispose(Strings, Done);
  inherited Done;
end;

procedure TDriveList.FocusItem;
begin
  inherited FocusItem(Item);
  EnableCommands([cmOk]);
  Message(Owner, evCommand, cmListSelectDrive + Item, Nil);
end;

procedure TDriveList.InsertItem(s: String);
begin
  List^.Insert(NewStr(s));
  SetRange(Range + 1);
  DrawView;
end;

procedure TDriveList.DeleteItem(index: Integer);
begin
  if List^.Count > 0 then begin
    DisposeStr(List^.Items^[index]);
    List^.Delete(List^.Items^[index]);
    SetRange(Range - 1);
    DrawView;
  end;
end;

procedure TDriveList.Clear;
begin
  while List^.Count > 0 do begin
    DisposeStr(List^.Items^[0]);
    List^.Delete(List^.Items^[0]);
  end;
  SetRange(0);
  DrawView;
end;


{ TDrivesInfo }

procedure TDrivesInfo.Draw;
begin
  inherited Draw;
  with PDriveDialog(Owner)^ do begin
   if (FDriveCount > 0) and (FCurrentDrive > -1) then begin
     Self.WriteStr(0, 0, DriveString[FDrives[FCurrentDrive].Cable], 2);
     Self.WriteStr(0, 1, GetValue(FDrives[FCurrentDrive].SerialNo), 2);
     Self.WriteStr(0, 2, GetValue(FDrives[FCurrentDrive].Firmware), 2);
     Self.WriteStr(0, 3, IntToStr(FDrives[FCurrentDrive].Cylinders), 2);
     Self.WriteStr(0, 4, IntToStr(FDrives[FCurrentDrive].Heads), 2);
     Self.WriteStr(0, 5, IntToStr(FDrives[FCurrentDrive].Sectors), 2);
     Self.WriteStr(0, 6, IntToStr(FDrives[FCurrentDrive].TotalSectors), 2);
     Self.WriteStr(0, 7, IntToStr(FDrives[FCurrentDrive].TotalSectors div 2048) + ' MB', 2);
   end;
 end;
end;


{ TDriveDialog }

constructor TDriveDialog.Init;
var
  R: TRect;
  ScrollBar: PScrollBar;
  Control: PView;

begin
  R.Assign(1, 1, 50, 21);
  inherited Init(R, 'Select drive');

  R.Assign(3, 8, 17, 9);
  Control := New(PStaticText, Init(R, 'Cable:'));
  Insert(Control);

  R.Assign(3, 9, 17, 10);
  Control := New(PStaticText, Init(R, 'Serial number:'));
  Insert(Control);

  R.Assign(3, 10, 15, 11);
  Control := New(PStaticText, Init(R, 'Firmware:'));
  Insert(Control);

  R.Assign(3, 11, 23, 12);
  Control := New(PStaticText, Init(R, 'Number of cylinders:'));
  Insert(Control);

  R.Assign(3, 12, 20, 13);
  Control := New(PStaticText, Init(R, 'Number of heads:'));
  Insert(Control);

  R.Assign(3, 13, 21, 14);
  Control := New(PStaticText, Init(R, 'Sectors per track:'));
  Insert(Control);

  R.Assign(3, 14, 19, 15);
  Control := New(PStaticText, Init(R, 'Total sectors:'));
  Insert(Control);

  R.Assign(3, 15, 15, 16);
  Control := New(PStaticText, Init(R, 'Capacity:'));
  Insert(Control);

  R.Assign(45, 3, 46, 7);

  New(ScrollBar, Init(R));
  Insert(ScrollBar);

  R.Assign(3, 3, 45, 7);
  DriveList := New(PDriveList, Init(R, 1, ScrollBar));
  Insert(DriveList);

  R.Assign(2, 2, 22, 3);
  Control := New(PLabel, Init(R, 'D~r~ives', DriveList));
  Insert(Control);

  R.Assign(2, 17, 13, 19);
  Control := New(PButton, Init(R, 'Op~t~ions', cmDetectOptions, bfNormal));
  Insert(Control);

  R.Assign(14, 17, 24, 19);
  Control := New(PButton, Init(R, '~D~etect', cmDetect, bfNormal));
  Insert(Control);

  R.Assign(25, 17, 35, 19);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(36, 17, 46, 19);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  R.Assign(24, 8, 45, 16);
  DrivesInfo := New(PDrivesInfo, Init(R));
  Insert(DrivesInfo);

  Options := Options + ofCentered;

  FDetectOptions := Config^.Data.DetectOptions;

  Message(@Self, evCommand, cmDetect, Nil);

  DriveList^.Focus;
end;

procedure TDriveDialog.HandleEvent(var Event: TEvent);
begin
  if (Event.Command = cmOk) and (FDriveCount = 0) then
    ClearEvent(Event);

  inherited HandleEvent(Event);




  if Event.KeyCode = kbF5 then
    Detect;

  if Event.What = evCommand then begin
    case Event.Command of
      cmSelect: Message(Owner, evCommand, cmOk, nil);
      cmDetect: Detect;
      cmDetectOptions: OptionsDialog;
    end;

    if (Event.Command >= cmListSelectDrive) then begin
       FCurrentDrive := Event.Command - cmListSelectDrive;
       DrivesInfo^.Draw;
    end;

    ClearEvent(Event);
  end;
end;


procedure TDriveDialog.Detect;
var
  i: Integer;
begin

  DetectDrives := New(PDetectDrives, Init(FDetectOptions));

  Desktop^.ExecView(DetectDrives);
  Move(DetectDrives^.FDrives, FDrives, SizeOf(FDrives));
  FDriveCount := DetectDrives^.FDriveCount;
  Dispose(DetectDrives, Done);

  FCurrentDrive := -1;
  DriveList^.Clear;

  for i := 0 to FDriveCount - 1 do
    DriveList^.InsertItem(GetValue(FDrives[i].Model));

  if FDriveCount > 0 then
    DriveList^.FocusItem(0)
  else
    DriveList^.InsertItem('No drives detected');

  DrivesInfo^.Draw;
end;


procedure TDriveDialog.OptionsDialog;
var
  DetectOptionsDialog: PDetectOptionsDialog;

begin
  DetectOptionsDialog := New(PDetectOptionsDialog, Init);
  DetectOptionsDialog^.SetData(FDetectOptions);

  if Desktop^.ExecView(DetectOptionsDialog) = cmOK then
    DetectOptionsDialog^.GetData(FDetectOptions);

  Dispose(DetectOptionsDialog, Done);
end;


procedure TDriveDialog.GetData;
begin
  if FCurrentDrive > -1 then begin
    Move(FDrives[FCurrentDrive], TProjectRec(Rec).DriveInfo,  SizeOf(TDriveInfo));

    with TProjectRec(Rec) do begin
      Geometry.LBASupported := FDrives[FCurrentDrive].TotalSectors > 0;
      if Geometry.LBASupported then
        Geometry.Mode := 0
      else
        Geometry.Mode := 1;

      Geometry.AddressableSectors := FDrives[FCurrentDrive].TotalSectors;
      Geometry.Cylinders := FDrives[FCurrentDrive].Cylinders;
      Geometry.Heads := FDrives[FCurrentDrive].Heads;
      Geometry.Sectors := FDrives[FCurrentDrive].Sectors;
    end;

  end;
end;


{ TSelectDriveDialog }

constructor TSelectDriveDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 38, 10);
  inherited Init(R, 'Select drive');
  Options := Options + ofCentered;

  R.Assign(3, 3, 25, 8);
  DriveCheck := New(PRadioButtons, Init(R,
    NewSItem('~A~uto detect',
    NewSItem('Primary ~M~aster',
    NewSItem('Primary ~S~lave',
    NewSItem('S~e~condary Master',
    NewSItem('Secondary S~l~ave', nil)))))));
  Insert(DriveCheck);

  R.Assign(2, 2, 20, 3);
  Control := New(PLabel, Init(R, 'Drive cable', DriveCheck));
  Insert(Control);

  R.Assign(26, 3, 36,  5);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(26, 5, 36, 7);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  DriveCheck^.Focus;
end;


procedure TSelectDriveDialog.GetData;
begin
  TProjectRec(Rec).DriveInfo.Cable := DriveCheck^.Value - 1;
end;

procedure TSelectDriveDialog.SetData;
begin
  DriveCheck^.Value := TProjectRec(Rec).DriveInfo.Cable + 1;
end;

end.