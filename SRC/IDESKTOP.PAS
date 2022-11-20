unit IDesktop;

interface

uses Views, Drivers, Objects, Dos;

type


  PMemory = ^TMemory;
  TMemory = object(TView)
    LastSize: Longint;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    procedure Update; virtual;
    function GetPalette: PPalette; virtual;
  end;


  PTime = ^TTime;
  TTime = object(TView)
    TimeChange: Byte;
    LastTime: DateTime;
    TimeStr: String[10];

    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    procedure Update;
    function FormatTime(hour, min, sec: Word): string;
    function GetPalette: PPalette; virtual;

  end;

implementation

{ TMemory }

constructor TMemory.Init;
begin
  inherited Init(Bounds);
  LastSize := 0;
end;

procedure TMemory.Draw;
var
  MemStr: String;
  Buffer: TDrawBuffer;
  Color: Byte;
begin
  LastSize := MemAvail;
  Str(LastSize:6, MemStr);
  Color := GetColor(1);
  MoveChar(Buffer, ' ', Color, Size.X);
  MoveStr(Buffer, 'Free memory: ' + MemStr, Color);
  WriteLine(0, 0, Size.X, 1, Buffer);
end;

procedure TMemory.Update;
begin
  if LastSize <> MemAvail then
    DrawView;
end;

function TMemory.GetPalette: PPalette;
const
  CMemory: TPalette = #3;
begin
  GetPalette := @CMemory;
end;


{ TTime }

constructor TTime.Init;
begin
  inherited Init(Bounds);
  FillChar(LastTime, SizeOf(LastTime), #$FF);
  TimeStr := '';
  TimeChange := 1;
end;

procedure TTime.Draw;
begin
  WriteChar(0, 0, ' ', 1, Size.X);
  WriteStr(0, 0, TimeStr, 1);
end;

procedure TTime.Update;
var
  h, m, s, s100: Word;
begin
  GetTime(h, m, s, s100);
  if Abs(s - LastTime.Sec) >= TimeChange then begin
    with LastTime do begin
      Hour := h;
      Min := m;
      Sec := s;
    end;
    TimeStr := FormatTime(h, m, s);
    DrawView;
  end;
end;

function TTime.FormatTime;

  function FirstZero(w: Word): String;
  var
    s: String;
  begin
    Str(w:0, s);
    FirstZero := Copy('00', 1, 2 - Length(s)) + s;
  end;

begin
  FormatTime := ' ' + FirstZero(hour) + ':' + FirstZero(min) + ':' + FirstZero(sec)
end;

function TTime.GetPalette: PPalette;
const
  CMemory: TPalette = #3;
begin
  GetPalette := @CMemory;
end;


end.