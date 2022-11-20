unit INew;

interface

uses Objects, Views, Dialogs, Drivers, App, IDrive, ITypes, IProject, IConfig;

type
  PGeometryType = ^TGeometryType;
  TGeometryType = object(TRadioButtons)
    function Mark(Item: Integer): Boolean; virtual;
  end;

  PNewDialog = ^TNewDialog;
  TNewDialog = object(TDialog)
    ProjectName: PInputLine;
    TotalSectors: PInputLine;
    Cylinders, Heads, Sectors: PInputLine;
    GeometryType: PGeometryType;
    Geometry: Byte;

    DriveDialog: PDriveDialog;
    ProjectRec: TProjectRec;
    FProjectOptions: TProjectOptionsRec;
    FName: String;

    constructor Init(ATitle: String);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure DetectDrives;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure SetMode(Mode: Byte);
    function GetCHSCapacity: Longint;
    function Recalculate: Boolean;
    procedure OptionsDialog;
    function CheckProject(Name: String): Boolean;
  end;



implementation

uses MsgBox, Dos, ICmd, IConst, IProcs, IOptions;


{ TNewDialog }

constructor TNewDialog.Init;
var
  R: TRect;
  Control: PView;

begin
  R.Assign(0, 0, 44, 16);

  Inherited Init(R, ATitle);
  Options := Options + ofCentered;

  R.Assign(16, 2, 26, 3);
  ProjectName := New(PInputLine, Init(R, 8));
  Insert(ProjectName);

  R.Assign(2, 2, 15, 3);
  Control := New(PLabel, Init(R, '~P~roject name', ProjectName));
  Insert(Control);

  R.Assign(3, 5, 41, 6);
  GeometryType := New(PGeometryType, Init(R,
    NewSItem('~L~BA ',
    NewSItem('~C~HS ',
    NewSItem('~D~etect drive', nil)))));

  Insert(GeometryType);

  GeometryType^.Press(2);

  R.Assign(2, 4, 26, 5);
  Control := New(PLabel, Init(R, 'Drive geometry', GeometryType));
  Insert(Control);


  R.Assign(3, 9, 19, 10);
  TotalSectors := New(PInputLine, Init(R, 10));
  Insert(TotalSectors);

  R.Assign(2, 7, 15, 8);
  Control := New(PLabel, Init(R, '~A~ddressable', TotalSectors));
  Insert(Control);

  R.Assign(2, 8, 15, 9);
  Control := New(PLabel, Init(R, 'sectors', TotalSectors));
  Insert(Control);


  R.Assign(33, 7, 41, 8);
  Cylinders := New(PInputLine, Init(R, 6));
  Insert(Cylinders);

  R.Assign(22, 7, 32, 8);
  Control := New(PLabel, Init(R, 'C~y~linders', Cylinders));
  Insert(Control);


  R.Assign(33, 9, 38, 10);
  Heads := New(PInputLine, Init(R, 3));
  Insert(Heads);

  R.Assign(22, 9, 28, 10);
  Control := New(PLabel, Init(R, '~H~eads', Heads));
  Insert(Control);

  R.Assign(33, 11, 37, 12);
  Sectors := New(PInputLine, Init(R, 2));
  Insert(Sectors);

  R.Assign(22, 11, 30, 12);
  Control := New(PLabel, Init(R, '~S~ectors', Sectors));
  Insert(Control);


  R.Assign(8, 13, 19, 15);
  Control := New(PButton, Init(R, 'Op~t~ions', cmProjectOptions, bfNormal));
  Insert(Control);


  R.Assign(20, 13, 30,  15);
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert(Control);

  R.Assign(31, 13, 41, 15);
  Control := New(PButton, Init(R, 'Cancel', cmOk, bfNormal));
  Insert(Control);

  if Project = nil then
    ProjectRec.DriveInfo.Cable := -1;

  ProjectName^.Focus;


  if Project = nil then
    FProjectOptions := Config^.Data.ProjectOptions
  else
    FProjectOptions := Project^.Data.Options;

end;


procedure TNewDialog.HandleEvent;
begin
  if (Event.What = evCommand) and (Event.Command = cmOk) then begin


    if ProjectName^.Data^ = '' then begin
      ProjectName^.Focus;
      Exit;
    end;

    if (ProjectName^.Data^ <> FName) and CheckProject(ProjectName^.Data^) then begin
      MessageBox('Project ' + ProjectName^.Data^ + ' already exist. You must change project name.',
        nil, mfInformation or mfOkButton);
      ClearEvent(Event);
      Exit;
    end;

    if Recalculate then
      ClearEvent(Event);

    if GeometryType^.Mark(2) then begin
      ClearEvent(Event);
      DetectDrives;
    end;
  end;

  if (Event.What = evCommand) and (Event.Command = cmOk) then begin
    if (GetCHSCapacity > MaxCHSCapacity) then begin
      Cylinders^.Data^ := '16383';
      Heads^.Data^ := '16';
      Sectors^.Data^ := '63';
    end;

  if GeometryType^.Value = 1 then
    TotalSectors^.Data^ := IntToStr(GetCHSCapacity);

  end;

  inherited HandleEvent(Event);

  if Event.What = evCommand then begin
    if (Event.Command >= cmSelectGeometry) then begin
       Geometry := Event.Command - cmSelectGeometry;
       TotalSectors^.SetState(sfDisabled, Geometry in [1, 2] );
       Cylinders^.SetState(sfDisabled, Geometry in [0, 2] );
       Sectors^.SetState(sfDisabled, Geometry in [0, 2] );
       Heads^.SetState(sfDisabled, Geometry in [0, 2]);
       ClearEvent(Event);
    end;

    if Event.Command = cmProjectOptions then
      OptionsDialog;
  end;
end;

procedure TNewDialog.OptionsDialog;
var
  ProjectOptionsDialog: PProjectOptionsDialog;

begin
  ProjectOptionsDialog := New(PProjectOptionsDialog, Init);


  ProjectOptionsDialog^.SetData(FProjectOptions);

  if Desktop^.ExecView(ProjectOptionsDialog) = cmOK then
    ProjectOptionsDialog^.GetData(FProjectOptions);


  Dispose(ProjectOptionsDialog, Done);
end;



procedure TNewDialog.GetData;
begin
  with TProjectRec(Rec) do begin
    Name := ProjectName^.Data^;
    Geometry.Mode := GeometryType^.Value;
    Geometry.LBASupported := ProjectRec.Geometry.LBASupported;
    Geometry.AddressableSectors := StrToInt(TotalSectors^.Data^);
    Geometry.Cylinders := StrToInt(Cylinders^.Data^);
    Geometry.Heads := StrToInt(Heads^.Data^);
    Geometry.Sectors := StrToInt(Sectors^.Data^);
    Options := FProjectOptions;
  end;
  Move(ProjectRec.DriveInfo, TProjectRec(Rec).DriveInfo,  SizeOf(TDriveInfo));
end;

procedure TNewDialog.SetData;
begin
  with TProjectRec(Rec) do begin
    ProjectName^.Data^ := Name;
    FName := Name;
    Cylinders^.Data^ := IntToStr(Geometry.Cylinders);
    Heads^.Data^ := IntToStr(TProjectRec(Rec).Geometry.Heads);
    Sectors^.Data^ := IntToStr(TProjectRec(Rec).Geometry.Sectors);
    TotalSectors^.Data^ := IntToStr(TProjectRec(Rec).Geometry.AddressableSectors);
    GeometryType^.Press(Geometry.Mode)
  end;
end;


procedure TNewDialog.SetMode;
begin
  GeometryType^.Press(Mode);
  case Mode of
    0: TotalSectors^.Focus;
    1: Cylinders^.Focus;
  end;
end;


procedure TNewDialog.DetectDrives;
begin
  DriveDialog := New(PDriveDialog, Init);
  if Desktop^.ExecView(DriveDialog) = cmOk then begin
    DriveDialog^.GetData(ProjectRec);

    Cylinders^.Data^ := IntToStr(ProjectRec.Geometry.Cylinders);
    Heads^.Data^ := IntToStr(ProjectRec.Geometry.Heads);
    Sectors^.Data^ := IntToStr(ProjectRec.Geometry.Sectors);
    TotalSectors^.Data^ := IntToStr(ProjectRec.Geometry.AddressableSectors);
    if ProjectRec.Geometry.LBASupported then
      SetMode(0)
    else
      SetMode(1);

    Redraw;

  end;
  Dispose(DriveDialog, Done);
end;

function TNewDialog.CheckProject;
var
  DirInfo: SearchRec;
  Path: String;

begin
  if Project = nil then
    Path := Config^.Data.ProjectOptions.ProjectsDirectory
  else
    Path := Project^.Data.Options.ProjectsDirectory;

  if not IsPathDelimiter(Path) then
    Path := Path + '\';

  FindFirst(Path + Name + '.ide', Archive, DirInfo);
  CheckProject := DosError = 0
end;


function TNewDialog.GetCHSCapacity: Longint;
var
  c, h, s: Longint;

begin
  c := StrToInt(Cylinders^.Data^);
  h := StrToInt(Heads^.Data^);
  s := StrToInt(Sectors^.Data^);
  GetCHSCapacity := c * h * s;
end;

function TNewDialog.Recalculate;
var
  Total: Longint;

begin
  Total := GetCHSCapacity;
  Recalculate := False;

  if (Total > MaxCHSCapacity) and (GeometryType^.Value = 1) then begin
    if (MessageBox('CHS capacity is too big. (max 8Gb)'#13'Do you want to recalculate LBA ?',
      nil, mfConfirmation or mfYesButton or mfNoButton) = 12) then begin
      Cylinders^.Data^ := '16383';
      Heads^.Data^ := '16';
      Sectors^.Data^ := '63';
      TotalSectors^.Data^ := IntToStr(Total);
      SetMode(0);
      Redraw;
    end;
    Recalculate := True;
  end;
end;


{ TGeometryType }

function TGeometryType.Mark(Item:Integer): Boolean;
var
  Result: Boolean;
begin
  Result := inherited Mark(Item);
  if Result then
    Message(Owner, evCommand, cmSelectGeometry + Item, nil);
  Mark := Result
end;

end.