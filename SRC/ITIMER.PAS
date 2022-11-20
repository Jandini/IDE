Unit ITimer;

interface

var
  TickCount: Longint;
  Value: Longint;
  Transfer: Longint;
  SuspendTimer: Boolean;

procedure InitTimer;
procedure DoneTimer;

implementation

uses IConst, Dos;

var
  LastValue: Longint;
  Int1CSave: Pointer;


{$F+,S-,W-}
procedure TimerHandler; interrupt;
begin
  if not SuspendTimer then begin
    Inc(TickCount);
    if (TickCount mod 18) = 0 then begin
      Transfer := Value - LastValue;
      LastValue := Value;
    end;
  end;
end;
{$F-,S+}

procedure InitTimer;
begin
  LastValue := 0;
  SuspendTimer := False;
  GetIntVec($1C, Int1CSave);
  SetIntVec($1C, @TimerHandler);
end;

procedure DoneTimer;
begin
  SetIntVec($1C, Int1CSave);
end;

end.
