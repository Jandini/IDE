unit IGauges;

{$V-}

interface

uses Drivers, Objects, Views;

const
  cmUpdateGauge = 12000;
  cmResetGauge = 12001;
  cmAddGauge   = 12002;

type
  PPercentGauge = ^TPercentGauge;
  TPercentGauge = object(TView)
    MaxValue: Longint;
    CurValue: Longint;
    constructor Init(var Bounds: TRect; AMaxValue: Longint);
    procedure Update(Progress: Longint); virtual;
    procedure AddProgress(Progress: Longint);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PBarGauge = ^TBarGauge;
  TBarGauge = object(TPercentGauge)
    procedure Draw; virtual;
  end;

implementation

constructor TPercentGauge.Init(var Bounds: TRect; AMaxValue: Longint);
begin
  inherited Init(Bounds);
  EventMask := EventMask or evBroadcast;
  MaxValue := AMaxValue;
  CurValue := 0;
end;


procedure TPercentGauge.Update(Progress: Longint);
begin
  CurValue := Progress;
  DrawView;
end;

procedure TPercentGauge.AddProgress(Progress: Longint);
begin
  Update(Progress + CurValue);
end;

procedure TPercentGauge.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmUpdateGauge :
        begin
          Update(Event.InfoLong);
        end;
      cmResetGauge:
        begin
          MaxValue := Event.InfoLong;
          Update(0);
        end;
{      cmAddGauge:
        begin
          AddProgress(Event.InfoLong);
        end;}
    end;
  end;
end;


{ TBarGauge }
procedure TBarGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
  FillSize: Longint;
begin
  C := GetColor(1);
  MoveChar(B, #176, C, Size.X);


  FillSize := Round( ((CurValue / MaxValue) * Size.X));

  MoveChar(B, #178, C, FillSize);
  WriteLine(0,0,Size.X,Size.Y,B);
end;

end.