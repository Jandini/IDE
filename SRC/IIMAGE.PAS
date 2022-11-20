Unit IImage;

interface

uses Dialogs, IStream, Drivers, Objects, Views, IGauges, ITypes, IMap;

type

  PPrepareImage = ^TPrepareImage;
  TPrepareImage = object(TDialog)

    FDir: String[80];
    FPrepared: Boolean;
    FProgressBar: PBarGauge;
    FImageSize: Longint;
    FImageStream: PImageStream;
    FMap: PMap;
    FImageName: String;
    FSectors: PStaticText;
    FSectorsText: PString;
    FLabel: PStaticText;


    constructor Init;
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure Prepare;

  end;

implementation

uses MsgBox, IProject, ICmd, IProcs, IApp, IConst, ICrt;

constructor TPrepareImage.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 42, 10);
  inherited Init(R, 'Preparing image');

  Options := Options + ofCentered;
  FImageSize := Project^.GetCapacity;

  R.Assign(3, 2, 30, 3);
  Control := New(PStaticText, Init(R, 'Image size: ' + Project^.GetStrCapacity));
  Insert(Control);


  R.Assign(3, 4, 40, 5);
  FLabel := New(PStaticText, Init(R,'Progress:                 '));
  Insert(FLabel);

  R.Assign(13, 4, 40, 5);
  FSectors := New(PStaticText, Init(R,'0.00MB                     '));
  Insert(FSectors);


  R.Assign(3, 5, 39, 6);
  FProgressBar := New(PBarGauge, Init(R, FImageSize));
  Insert(FProgressBar);

  R.Assign(3, 6, 40, 7);
  Control := New(PStaticText, Init(R, '0%              50%             100%'));
  Insert(Control);

  FImageSize := FImageSize;
  FImageName := Project^.GetImageName;
end;

destructor TPrepareImage.Done;
begin
  Dispose(FProgressBar, Done);
  inherited Done;
end;

procedure TPrepareImage.HandleEvent;
begin
  inherited HandleEvent(Event);

  if (State and sfVisible = sfVisible) and (not FPrepared) then begin
    FPrepared := True;
    Prepare;
  end;
end;

procedure TPrepareImage.Draw;
begin
  inherited Draw;
  WriteStr(1, 8, '           Press Esc to cancel          ', 19)
end;



procedure TPrepareImage.Prepare;
var
  i, j: Longint;
  Buf: Array[0..511] of byte;
  Break: Boolean;
  Result: Boolean;
  WriteError: Boolean;
  TempStr: String;

begin

  FMap := New(PMap, Init(FImageName));
  FMap^.SetSize(FImageSize);
  FMap^.Flush;
  Dispose(FMap, Done);

  FImageStream := New(PImageStream, Init(FImageName, stCreate));

  if FImageStream^.Status = stOk then begin

    i := 0;
    Break := False;

    while (i < FImageSize) and (not Break) do begin

      repeat

        FillChar(Buf, SizeOf(Buf), $0);
        TempStr := IntToStr(i);
        Move(TempStr[1], Buf[0], Byte(TempStr[0]));

        FImageStream^.Write(Buf, 1);

        WriteError := FImageStream^.Status <> stOk;

        if WriteError then
          Break := not (SystemError(10, Ord(UpCase(Project^.Data.Options.ImagesDirectory[1])) - 65 ) = 0);

      until (not WriteError) or (Break);


     if Integer(i) mod 2000 = 0 then begin

       FProgressBar^.Update(i);
       Str(i / 2048:1:2, TempStr);
       TempStr := TempStr + 'MB';
       Move(TempStr[1], FSectors^.Text^[1], Length(TempStr));


       FSectors^.Draw;
       IDEApplication.Idle;
     end;

     if KeyPressed then
       if ReadKey = #27 then
         Break := MessageBox('Do you want to cancel?',
           nil, mfConfirmation or mfYesButton or mfNoButton) = 12;

     inc(i);
   end;


  end else
    MessageBox('Cannot create image stream. (' + FImageName + ')' , nil, mfError or mfOkButton);


  if KeyPressed then
    repeat ReadKey until not KeyPressed;

  Dispose(FImageStream, Done);
  Message(@Self, evCommand, cmOk, nil);
end;

end.