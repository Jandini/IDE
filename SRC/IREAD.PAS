Unit IRead;

interface

uses Dialogs, IStream, Drivers, Objects, Views, IGauges, ITypes, IMap;

type


  PReadBlocks = ^TReadBlocks;
  TReadBlocks = object(TDialog)
    FProgressBar: PBarGauge;
    FImageSize: Longint;
    FImageStream: PImageStream;
    FIDEStream: PIDEStream;
    FRead: Boolean;
    FBuffer: Pointer;
    FMap: PMap;
    FCurrent: PStaticText;

    FStartSector, FEndSector: Longint;

    constructor Init(var FSectors: TSectorsRec);
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure ReadBlocks;

  end;

implementation

uses App, MsgBox, IProject, ICmd, IProcs, IApp, IConst, ICrt, IOptions;

constructor TReadBlocks.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 42, 10);
  inherited Init(R, 'Reading sectors');

  FStartSector := FSectors.StartSector;
  FEndSector := FSectors.EndSector;

  Options := Options + ofCentered;

  R.Assign(3, 2, 30, 3);
  Control := New(PStaticText, Init(R, 'Image size: ' + Project^.GetStrCapacity));
  Insert(Control);


  R.Assign(3, 4, 40, 5);
  FCurrent := New(PStaticText, Init(R,'Reading sector:                    '));
  Insert(FCurrent);

  FImageSize := 1;

  R.Assign(3, 5, 39, 6);
  FProgressBar := New(PBarGauge, Init(R, FEndSector - FStartSector));
  Insert(FProgressBar);

  R.Assign(3, 6, 40, 7);
  Control := New(PStaticText, Init(R, '0%              50%             100%'));
  Insert(Control);

end;

destructor TReadBlocks.Done;
begin
  Dispose(FProgressBar, Done);
  inherited Done;
end;

procedure TReadBlocks.HandleEvent;
begin
  inherited HandleEvent(Event);

  if (State and sfVisible = sfVisible) and (not FRead) then begin
    FRead := True;
    ReadBlocks;
  end;
end;

procedure TReadBlocks.Draw;
begin
  inherited Draw;
  WriteStr(1, 8, '           Press Esc to cancel          ', 19)
end;



procedure TReadBlocks.ReadBlocks;
var
  i: Longint;
  TempStr: String;

begin

  FImageStream := New(PImageStream, Init(Project^.GetImageName, stOpen));
  FIDEStream := New(PIDEStream, Init(DriveList[Project^.Data.DriveInfo.Cable], stOpen));
  FMap := New(PMap, Init(Project^.GetImageName));

  GetMem(FBuffer, 1024);

  i := FStartSector;
  FIDEStream^.Flags := fBusyCheck + fHazardCheck + fReadyCheck+ fDataCheck;

  while (i < FEndSector) and (Port[$60] <> 1) do begin
    FillChar(FBuffer^, 1024, $EE);
    FIDEStream^.Seek(i);
    repeat
      FIDEStream^.Read(FBuffer^, 1);
    until (Boolean(FIDEStream^.DriveFlags and 64)) or (Port[$60] = 1);

    FImageStream^.Seek(i);
    FImageStream^.Write(FBuffer^, 1);

    if FIDEStream^.Status = stOk then
      FMap^.SetSector(i, $B0)
    else
      FMap^.SetSector(i, 66);

    if Integer(i) mod 256 = 0 then begin
       FProgressBar^.Update(i - FStartSector);
       IDEApplication.Idle;
       TempStr := IntToStr(i);
       Move(TempStr[1], FCurrent^.Text^[17], Length(TempStr));
       FCurrent^.Draw;


     end;

    inc(i, 1);
  end;



  FMap^.Flush;
  FreeMem(FBuffer, 1024);
  Dispose(FImageStream, Done);
  Dispose(FIDEStream, Done);
  Dispose(FMap, Done);


  Message(@Self, evCommand, cmOk, nil);
end;

end.