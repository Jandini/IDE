Unit IProject;

interface

uses Views, Objects, Drivers, ITypes, IConfig, WinDos;

type

  PProjectText = ^TProjectText;
  TProjectText = object(TView)
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
  end;

  PProject = ^TProject;
  TProject = object(TWindow)
    FStream: PDosStream;
    Text: PProjectText;
    Data: TProjectRec;
    Saved: Boolean;

    constructor Init;
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    function CloseQuery: Boolean;
    function GetStrCapacity: String;
    function GetCapacity: Longint;
    function GetImageName: String;
    function GetMapName: String;
    function CheckImage: Boolean;

    function Load(FileName: String): Boolean;
    function Save: Boolean;
  end;


var
  Project: PProject;

implementation



uses MsgBox, IConst, ICmd, IProcs, IStream, IApp, App;

{ TProject }

constructor TProject.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(4, 2, 60, 19);
  inherited Init(R, 'Project', 0);

  Flags := Flags - wfGrow;
  GetClipRect(R);
  R.Grow(-1, -1);
  Text := New(PProjectText, Init(R));
  Insert(Text);

  with Data do begin
    DriveInfo.Cable := -1;
    Move(ProjectHeader, Header, SizeOf(Header));
  end;

  EnableCommands([cmSelectDrive, cmEditProject, cmSave, cmPrepareImage]);

end;

destructor TProject.Done;
begin
  DisableCommands([cmSelectDrive, cmEditProject, cmSave, cmPrepareImage]);
  inherited Done;
  Project := nil;
  IDEApplication.UpdateMenu;
end;

procedure TProject.HandleEvent;
begin
  if Event.Command = cmClose then
    if not CloseQuery then
      ClearEvent(Event);

  inherited HandleEvent(Event);
end;


procedure TProject.Draw;
var
  R: TRect;
begin
  inherited Draw;
  Text^.DrawView;

  if not Saved then begin
    GetExtent(R);
    WriteStr(3, R.B.Y - 1, #32#15#32, 2);
  end;
end;

function TProject.CloseQuery;
var
  Result: Integer;
begin
  if Not Saved then begin
    Result := MessageBox('Project has been modified. Do you want save project?',
      nil, mfConfirmation or mfYesNoCancel);

    if Result = 12 then
      if not Save then
        Result := 11;

    CloseQuery := Result <> 11;
  end;
end;

function TProject.GetStrCapacity;
var
  c: Longint;
  s: String;
begin
  with Data.Geometry do begin
    case Mode of
      0: c := AddressableSectors;
      1: c := Longint(Cylinders) * Sectors * Heads;
    end;
  end;
  Str(c / 2048:1:2, s);
  GetStrCapacity := s + 'MB';
end;

function TProject.GetCapacity;
var
  c: Longint;

begin
  with Data.Geometry do begin
    case Mode of
      0: c := AddressableSectors;
      1: c := Longint(Cylinders) * Sectors * Heads;
    end;
  end;
  GetCapacity := c;
end;

function TProject.GetMapName;
var
  s: String;

begin
  s := Data.Options.ImagesDirectory;
  if not IsPathDelimiter(s) then
    s := s + '\';
  if Data.Options.CreateSubDirectory = 1 then
    s := s + Data.Name + '\' + Data.Name;
  GetMapName := s;
end;


function TProject.GetImageName;
var
  s: String;

begin
  s := Data.Options.ImagesDirectory;
  if not IsPathDelimiter(s) then
    s := s + '\';
  if Data.Options.CreateSubDirectory = 1 then
    s := s + Data.Name + '\' + Data.Name;
  GetImageName := s;
end;

function TProject.Load;
begin
  Load := True;
  FStream := New(PDosStream, Init(FileName, stOpen));
  if FStream^.Status = stOk then begin
    FStream^.Read(Data, SizeOf(Data));
    Data.Image.Prepared := CheckImage;
  end
  else begin
    MessageBox('Cannot open file ' + FileName , nil, mfError or mfOkButton);
    Load := False;
  end;

  Dispose(FStream, Done);
  Saved := True;
end;

function TProject.Save;
begin
  {$I-}
  if IsPathDelimiter(Data.Options.ProjectsDirectory) then
    Data.Options.ProjectsDirectory := copy(Data.Options.ProjectsDirectory, 1, Length(Data.Options.ProjectsDirectory) - 1);
  ChDir(Data.Options.ProjectsDirectory);
  {$I+}
  if IoResult <> 0 then begin
    MessageBox('Projects directory not exist. Change driectory and try again.', nil, mfError or mfOkButton);
    Save := False;
    Exit;
  end;

  FStream := New(PDosStream, Init(Data.Name + '.ide', stCreate));
  if FStream^.Status = stOk then
    FStream^.Write(Data, SizeOf(Data));
  Dispose(FStream, Done);

  Saved := True;
  Save := True;
  DrawView;
end;


function TProject.CheckImage: Boolean;
var
  FImageStream: PImageStream;
  FSize: Longint;

begin
  FImageStream := New(PImageStream, Init(GetImageName, stOpen));

  FSize := 0;
  if FImageStream^.Status = stOk then
    FSize := FImageStream^.GetSize;

  Dispose(FImageStream, Done);

  CheckImage := FSize = GetCapacity;
end;

{ TProjectText }

constructor TProjectText.Init;
begin
  inherited Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
end;


procedure TProjectText.Draw;
const
  TextLeft = 25;

begin
  inherited Draw;

  WriteStr(2, 1, 'Name:', 1);
  WriteStr(2, 2, 'Image:', 1);
  WriteStr(2, 3, 'Read sectors:', 1);
  WriteStr(2, 4, 'Bad sectors:', 1);


  WriteStr(2, 6, 'Cable:', 1);
  WriteStr(2, 7, 'Geometry type:', 1);
  WriteStr(2, 8, 'Addressable sectors:', 1);
  WriteStr(2, 9, 'Cylinders:', 1);
  WriteStr(2, 10, 'Heads:', 1);
  WriteStr(2, 11, 'Sectors:', 1);

  if Project^.Data.Geometry.Mode = 0 then
    WriteStr(2, 12, 'Capacity (LBA):', 1)
  else
    WriteStr(2, 12, 'Capacity (CHS):', 1);


  WriteStr(TextLeft, 1, Project^.Data.Name, 3);

  if Project^.Data.Image.Prepared then
    WriteStr(TextLeft, 2, 'Prepared', 3)
  else
    WriteStr(TextLeft, 2, 'Not prepared', 3);

  WriteStr(TextLeft, 3, IntToStr(Project^.Data.ReadSectors), 3);
  WriteStr(TextLeft, 4, IntToStr(Project^.Data.BadSectors), 3);


  if Project^.Data.DriveInfo.Cable > -1 then
    WriteStr(TextLeft, 6, DriveString[Project^.Data.DriveInfo.Cable], 2)
  else
    WriteStr(TextLeft, 6, 'Not selected', 2);

  if Project^.Data.Geometry.Mode = 0 then
    WriteStr(TextLeft, 7, 'LBA', 2)
  else
    WriteStr(TextLeft, 7, 'CHS', 2);

  WriteStr(TextLeft, 8, IntToStr(Project^.Data.Geometry.AddressableSectors), 2);
  WriteStr(TextLeft, 9, IntToStr(Project^.Data.Geometry.Cylinders), 2);
  WriteStr(TextLeft, 10, IntToStr(Project^.Data.Geometry.Heads), 2);
  WriteStr(TextLeft, 11, IntToStr(Project^.Data.Geometry.Sectors), 2);
  WriteStr(TextLeft, 12, Project^.GetStrCapacity, 2);
end;


begin
  Project := nil;
end.