unit IDetect;

interface

uses Dialogs, Objects, Views, Drivers, IConst, ITypes, IStream, IConfig;

type

  PDetectDrives = ^TDetectDrives;
  TDetectDrives = object(TDialog)
    FDrives: Array[0..3] of TDriveInfo;
    FDriveCount: ShortInt;
    FIDEStream: PIDEStream;

    FDetectOptions: TDetectOptionsRec;

    constructor Init(DetectOptions: TDetectOptionsRec);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure Detect;

  end;

implementation

uses IApp, ICrt;

constructor TDetectDrives.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 38, 6);
  inherited Init(R, '');
  Options := Options + ofCentered;
  R.Assign(10, 2, 30, 3);
  Control := New(PStaticText, Init(R, 'Detecting drives...'));
  Insert(Control);
  FDetectOptions := DetectOptions;
end;

procedure TDetectDrives.HandleEvent;
begin
  inherited HandleEvent(Event);

  if (State and sfExposed = sfExposed) then begin
    State := State - sfExposed;
    Detect;
    Message(@Self, evCommand, cmOk, nil);
  end;

end;

procedure TDetectDrives.Draw;
begin
  inherited Draw;
  WriteStr(1, 4, '         Press Esc to cancel        ', 19)
end;


procedure TDetectDrives.Detect;
var
  i: Integer;
  Buf: TDriveInfo;
  EndDetect, CanDetect: Boolean;
  Detected: Byte;

begin
  EndDetect := False;
  Detected := 0;

  repeat
    FDriveCount := 0;

    i := 0;
    while (i < 4) and (not EndDetect) do begin

      case i of
        0: CanDetect := (FDetectOptions.DetectFlag and 1) = 1;
        1: CanDetect := (FDetectOptions.DetectFlag and 2) = 2;
        2: CanDetect := (FDetectOptions.DetectFlag and 4) = 4;
        3: CanDetect := (FDetectOptions.DetectFlag and 8) = 8;
      end;

      if CanDetect then begin
        FillChar(Buf, SizeOf(Buf), 0);

        FIDEStream := New(PIDEStream, Init(DriveList[i], stOpen));
        FIDEStream^.Flags := FDetectOptions.CheckFlag;
        FIDEStream^.Identify(Buf);

        if FIDEStream^.Status = stOk then begin
          Buf.Cable := i;

          case i of
            0: Detected := Detected or 1;
            1: Detected := Detected or 2;
            2: Detected := Detected or 4;
            3: Detected := Detected or 8;
          end;

          Move(Buf, FDrives[FDriveCount], SizeOf(Buf));
          Inc(FDriveCount);
        end;
        Dispose(FIDEStream, Done);
      end;

      Inc(i);
    end;

      if KeyPressed then
        EndDetect := ReadKey = #27;

    if not EndDetect then begin
      EndDetect := FDetectOptions.WaitFlag or Detected = Detected;

      if (EndDetect) and (FDetectOptions.WaitFlag > 0) and (FDetectOptions.OtherFlag and 1 = 1) then begin
      {  Sound(500); Delay(50);
        Sound(1000); Delay(50);
        NoSound;}
      end;
    end;

    IDEApplication.Idle;

  until (EndDetect) or (FDetectOptions.WaitFlag = 0);
  {Delay(100);}
  if KeyPressed then
    repeat ReadKey until not KeyPressed;
end;

end.