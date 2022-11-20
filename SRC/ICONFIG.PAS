Unit IConfig;

interface

uses Objects, ITypes;

type
  PConfig = ^TConfig;
  TConfig = object(TObject)
  private
    FStream: PDosStream;

  public
    Data: TConfigRec;

    constructor Init;
    procedure Load;
    procedure Save;
  end;

var
  Config: PConfig;

implementation

uses IConst, IApp;

{ TConfig }

constructor TConfig.Init;
begin
  inherited Init;
  FillChar(Data, SizeOf(Data), 0);
  with Data.DetectOptions do begin
    DetectFlag := 15;
    CheckFlag := 7;
    OtherFlag := 0;
  end;

  with Data.GeneralOptions do begin
    DesktopFlag := 7;
  end;

  with Data.ProjectOptions do begin
    ProjectsDirectory := 'C:\PROJECTS';
    ImagesDirectory := 'C:\';
    CreateSubDirectory := 1;
  end;

end;

procedure TConfig.Load;
begin
  FStream := New(PDosStream, Init(AppDir + ConfigFileName, stOpen));
  if FStream^.Status = stOk then
    FStream^.Read(Data, SizeOf(Data));
  Dispose(FStream, Done);
end;

procedure TConfig.Save;
begin
  FStream := New(PDosStream, Init(AppDir + '\' + ConfigFileName, stCreate));
  if FStream^.Status = stOk then
    FStream^.Write(Data, SizeOf(Data));
  Dispose(FStream, Done);
end;

end.