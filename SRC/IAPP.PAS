Unit IApp;

interface

uses App, Drivers, Objects, Menus, Views, StdDlg, IDesktop, IConfig;

type

  TIDEApplication = object(TApplication)
    Memory: PMemory;
    Time: PTime;

    constructor Init;
    destructor Done; virtual;
    procedure InitStatusLine; virtual;
    procedure InitMenuBar; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Idle; virtual;

    function WindowsEnv: Boolean;
    function CorrectName(Name: String): String;


    procedure Load(FileName: String);


    procedure NewDialog;
    procedure EditDialog;
    procedure OpenDialog;
    procedure SelectDriveDialog;
    procedure DetectOptionsDialog;
    procedure GeneralOptionsDialog;
    procedure ProjectOptionsDialog;
    procedure PrepareImage;
    procedure ReadBlocks;
    procedure Calculator;
    procedure AboutDialog;
    procedure UpdateMenu;
  end;


var
  IDEApplication: TIDEApplication;
  AppDir: String;

implementation

uses INew, IAbout, ICmd, IProject, IOptions, ICalc, IDrive, IImage,
  IRead, MsgBox, IOpen, Dos, ITypes;

{ TIDEApplication }

function TIDEApplication.CorrectName;
var
  s: String;
begin
  s := Name;

  if Pos('.', s) = 0 then begin
    s := Config^.Data.ProjectOptions.ProjectsDirectory + '\' + s + '.ide';
  end else
    s := Name;

  CorrectName := s;
end;

constructor TIDEApplication.Init;
var
  R: TRect;

begin
  if WindowsEnv then begin
    Writeln('Windows enviroment not supported.');
    Halt;
  end;

  inherited Init;

  DisableCommands([cmViewImage, cmWriteImage, cmPrepareImage, cmReadBlocks,
    cmVerifyBad, cmSave, cmSelectDrive, cmEditProject, cmReadOptions]);

  Config := New(PConfig, Init);
  Config^.Load;


  Memory := nil;
  Time := nil;

  with Config^.Data.GeneralOptions do begin
    if (DesktopFlag and 1) = 1 then begin
      GetExtent(R);
      R.A.X := R.B.X - 20;
      R.A.Y := R.B.Y - 1;
      Memory := New(PMemory, Init(R));
      Insert(Memory);
    end;

    if (DesktopFlag and 2) = 2 then begin
      GetExtent(R);
      R.A.X := R.B.X - 10;
      R.B.Y := R.A.Y + 1;
      Time := New(PTime, Init(R));
      Insert(Time);
    end;


    if ParamCount = 1 then
      Load(CorrectName(ParamStr(1)))
    else begin
      if (DesktopFlag and 4) = 4 then
        AboutDialog;

      if (DesktopFlag and 8) = 8 then
        Message(@Self, evCommand, cmNew, nil);
    end;
  end;

end;

destructor TIDEApplication.Done;
begin
  Dispose(Config, Done);
  inherited Done;
end;


procedure TIDEApplication.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R, NewStatusDef(0, $EFFF, StdStatusKeys(nil), nil)));
end;


procedure TIDEApplication.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~P~roject', hcNoContext, NewMenu(
      NewItem('~N~ew', 'Alt-N', kbAltN, cmNew, hcNoContext,
      NewItem('~O~pen', 'F3', kbF3, cmOpen, hcNoContext,
      NewItem('~E~dit     ', 'F4', kbF4, cmEditProject, hcNoContext,
      NewItem('~S~ave', 'F2', kbF2, cmSave, hcNoContext,
      NewItem('~D~rive...', 'Alt-D', kbAltD, cmSelectDrive, hcNoContext,
      NewLine(
      NewItem('~Q~uit', 'Alt-X', kbAltX, cmQuit, hcNoContext,
      nil)))))))),

    NewSubMenu('~I~mage', hcNoContext, NewMenu(
      NewItem('~P~repare', 'Alt-P', kbAltP, cmPrepareImage, hcNoContext,
      NewItem('~V~iew', 'Alt-V', kbAltV, cmViewImage, hcNoContext,
      NewItem('~W~rite', 'Alt-W', kbAltW, cmWriteImage, hcNoContext,
      nil)))),

     NewSubMenu('~R~ead', hcNoContext, NewMenu(
      NewItem('~R~ead blocks to image', '', 0, cmReadBlocks, hcNoContext,
      NewLine(
      NewItem('~V~erify bad blocks', '', 0, cmVerifyBad, hcNoContext,
      nil)))),


     NewSubMenu('~T~ools', hcNoContext, NewMenu(
      NewItem('~C~alculator', 'Alt-C', kbAltC, cmCalc, hcNoContext,
      nil)),

     NewSubMenu('~O~ptions', hcNoContext, NewMenu(
      NewItem('~G~eneral options', '', 0, cmGeneralOptions, hcNoContext,
      NewItem('~P~roject options', '', 0, cmProjectOptions, hcNoContext,
      NewItem('~D~etect options', '', 0, cmDetectOptions, hcNoContext,
      NewItem('~R~ead options', '', 0, cmReadOptions, hcNoContext,
      nil))))),

    NewSubMenu('~H~elp', hcNoContext, NewMenu(
      NewItem('~A~bout...', '', kbF1, cmAbout, hcNoContext,
      nil)),
    nil))
  )))))));
end;


procedure TIDEApplication.HandleEvent(var Event: TEvent);
begin

  if (Event.What = evCommand) and (Event.Command = cmQuit) then
   if (Project <> nil) then
     if (Project^.CloseQuery) then
       Dispose(Project, Done)
     else
       ClearEvent(Event);


  inherited HandleEvent(Event);

  if Event.What = evCommand then begin
    case Event.Command of
      cmNew: NewDialog;
      cmEditProject: EditDialog;
      cmOpen: OpenDialog;
      cmAbout: AboutDialog;
      cmPrepareImage: PrepareImage;
      cmReadBlocks: ReadBlocks;
      cmSelectDrive: SelectDriveDialog;
      cmDetectOptions: DetectOptionsDialog;
      cmGeneralOptions: GeneralOptionsDialog;
      cmProjectOptions: ProjectOptionsDialog;
      cmCalc: Calculator;
      cmSave: Project^.Save;
    end;
    ClearEvent(Event);
  end;
end;


procedure TIDEApplication.Idle;
begin
  Inherited Idle;
  if Memory <> nil then
    Memory^.Update;
  if Time <> nil then
    Time^.Update;
end;

procedure TIDEApplication.NewDialog;
var
  NewDlg: PNewDialog;

begin
  if (Project <> nil) then
    if (Project^.CloseQuery) then
      Dispose(Project, Done)
    else
      Exit;

  NewDlg := New(PNewDialog, Init('New project'));
  if Desktop^.ExecView(NewDlg) = cmOk then begin
    Project := New(PProject, Init);
    NewDlg^.GetData(Project^.Data);
    InsertWindow(Project);
  end;
  Dispose(NewDlg, Done);
end;

procedure TIDEApplication.EditDialog;
var
  EditDlg: PNewDialog;

begin
  EditDlg := New(PNewDialog, Init('Edit project'));
  EditDlg^.SetData(Project^.Data);

  if Desktop^.ExecView(EditDlg) = cmOk then begin
    EditDlg^.GetData(Project^.Data);
    Project^.Saved := False;
    Project^.Data.Image.Prepared := Project^.CheckImage;
    UpdateMenu;
    Project^.DrawView;
  end;
  Dispose(EditDlg, Done);
end;

procedure TIDEApplication.Load;
begin
  if Project <> nil then
    if (Project^.CloseQuery) then
      Dispose(Project, Done)
    else
      Exit;

  Project := New(PProject, Init);

  if Project^.Load(FileName) then
    InsertWindow(Project)
  else
    Dispose(Project, Done);

  UpdateMenu;

end;

procedure TIDEApplication.OpenDialog;
var
  ODialog: POpenDialog;
  FileName: String;

begin
  ODialog := New(POpenDialog, Init('Open project'));
  if Desktop^.ExecView(ODialog) = cmOk then begin
    ODialog^.GetData(FileName);
    Load(Config^.Data.ProjectOptions.ProjectsDirectory + '\' + FileName + '.ide');
  end;
end;

procedure TIDEApplication.PrepareImage;
var
  PrepareDialog: PPrepareImage;
  FDir: String[80];
  AnyErrors: Boolean;

begin
  AnyErrors := False;
  {$i-}
  GetDir(0, FDir);

  ChDir(Project^.Data.Options.ImagesDirectory);
  if IoResult <> 0 then begin
    MessageBox('Cannot open images directory. (' + Project^.Data.Options.ImagesDirectory + ')' ,
      nil, mfError or mfOkButton);
    AnyErrors := True;
  end;

  if Project^.Data.Options.CreateSubDirectory = 1 then begin

    ChDir(Project^.Data.Name);
    if IoResult <> 0 then begin
      MkDir(Project^.Data.Name);
      if IoResult <> 0 then begin
        MessageBox('Cannot create subdirectory for image.', nil, mfError or mfOkButton);
        AnyErrors := True;
      end;
    end;
  end;

  {$i+}

  if (Project^.GetCapacity = 0) and (not AnyErrors) then begin
    MessageBox('Capacity is 0MB. Change drive geometry and try again.', nil, mfInformation or mfOkButton);
    AnyErrors := True;
  end;

  if not AnyErrors then begin
    PrepareDialog := New(PPrepareImage, Init);
    Desktop^.ExecView(PrepareDialog);
    Dispose(PrepareDialog, Done);
    Project^.Data.Image.Prepared := Project^.CheckImage;
    Project^.Draw;
    UpdateMenu;
  end;
  {$i-}
  ChDir(FDir);
  {$i+}
end;




procedure TIDEApplication.ReadBlocks;
var
  ReadBlocksDialog: PReadBlocks;
  ReadOptionsDlg: PReadOptionsDialog;
  Sectors: TSectorsRec;


begin
  ReadOptionsDlg := New(PReadOptionsDialog, Init);
    ReadOptionsDlg^.SetData(Project^.Data.Geometry);
  if Desktop^.ExecView(ReadOptionsDlg) = cmOK then begin
    ReadOptionsDlg^.GetData(Sectors);
    Config^.Save;

    Dispose(ReadOptionsDlg, Done);
    ReadBlocksDialog := New(PReadBlocks, Init(Sectors));
    Desktop^.ExecView(ReadBlocksDialog);
    Dispose(ReadBlocksDialog, Done);
    UpdateMenu;
  end else
    Dispose(ReadOptionsDlg, Done);
end;


procedure TIDEApplication.DetectOptionsDialog;
var
  DetectOptionsDlg: PDetectOptionsDialog;

begin
  DetectOptionsDlg := New(PDetectOptionsDialog, Init);
  DetectOptionsDlg^.SetData(Config^.Data.DetectOptions);

  if Desktop^.ExecView(DetectOptionsDlg) = cmOK then begin
    DetectOptionsDlg^.GetData(Config^.Data.DetectOptions);
    Config^.Save;
  end;
  Dispose(DetectOptionsDlg, Done);
end;

procedure TIDEApplication.GeneralOptionsDialog;
var
  GeneralOptionsDlg: PGeneralOptionsDialog;

begin
  GeneralOptionsDlg := New(PGeneralOptionsDialog, Init);
  GeneralOptionsDlg^.SetData(Config^.Data.GeneralOptions);

  if Desktop^.ExecView(GeneralOptionsDlg) = cmOK then begin
    GeneralOptionsDlg^.GetData(Config^.Data.GeneralOptions);
    Config^.Save;
  end;

  Dispose(GeneralOptionsDlg, Done);
end;


procedure TIDEApplication.ProjectOptionsDialog;
var
  ProjectOptionsDlg: PProjectOptionsDialog;

begin
  ProjectOptionsDlg := New(PProjectOptionsDialog, Init);
  ProjectOptionsDlg^.SetData(Config^.Data.ProjectOptions);

  if Desktop^.ExecView(ProjectOptionsDlg) = cmOK then begin
    ProjectOptionsDlg^.GetData(Config^.Data.ProjectOptions);
    Config^.Save;
  end;

  Dispose(ProjectOptionsDlg, Done);
end;


procedure TIDEApplication.SelectDriveDialog;
var
  DriveDialog: PDriveDialog;
  SelectDriveDlg: PSelectDriveDialog;

begin
  SelectDriveDlg := New(PSelectDriveDialog, Init);

  SelectDriveDlg^.SetData(Project^.Data);

  if (Desktop^.ExecView(SelectDriveDlg) = cmOk) and (SelectDriveDlg^.DriveCheck^.Value = 0) then begin

    DriveDialog := New(PDriveDialog, Init);
    if Desktop^.ExecView(DriveDialog) = cmOk then begin
      DriveDialog^.GetData(Project^.Data);
      Project^.Saved := False;
      Project^.DrawView;
    end;


    Dispose(DriveDialog, Done);
  end else
    SelectDriveDlg^.GetData(Project^.Data);

  Project^.Text^.DrawView;

  Dispose(SelectDriveDlg, Done);
end;

procedure TIDEApplication.Calculator;
var
  Calc: PCalculator;
begin
  Calc := New(PCalculator, Init);
  Desktop^.ExecView(Calc);
  Dispose(Calc, Done);
end;

procedure TIDEApplication.AboutDialog;
begin
  ExecuteDialog(New(PAboutDialog, Init), nil);
end;

procedure TIDEApplication.UpdateMenu;
begin
  if (Project <> nil) then begin
    if (Project^.Data.Image.Prepared) then begin
      DisableCommands([cmPrepareImage]);
      EnableCommands([cmReadBlocks]);
    end
    else begin
      EnableCommands([cmPrepareImage]);
      DisableCommands([cmReadBlocks]);
    end;
  end
  else begin
    DisableCommands([cmPrepareImage, cmReadBlocks]);
  end;
end;

function TIDEApplication.WindowsEnv; assembler;
asm
  mov   ax, 1600h
  int   2Fh
  cmp   al, 4
  jb    @NoWin
  mov   ax, 1
  jmp   @Exit
@NoWin:
  mov   ax, 0;
@Exit:
end;


end.