{$A+,B-,D+,E+,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
Unit IProcs;

interface

function GetValue(AArray: Array of Char): String;
function IntToStr(Value: Longint): String;
function StrToInt(Value: String): Longint;
function IsPathDelimiter(Path: String): Boolean;

implementation




function Trim(const S: string): string;
var
  Result: String;
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= ' ' do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
  Trim := Result;
end;


function GetValue(AArray: Array of Char): String;
var
  Result: String;
  i: Integer;
begin
  Result := '';
  i := Low(AArray);
  while (i < High(AArray)) do begin
    Result := Result + (AArray[i + 1] + AArray[i]);
    inc(i, 2);
  end;
  GetValue := Trim(Result);
end;

function IntToStr(Value: Longint): String;
var
  s: String;
begin
  Str(Value, s);
  IntToStr := s;
end;

function StrToInt(Value: String): Longint;
var
  e: Integer;
  l: Longint;
begin
  val(Value, l, e);
  StrToInt := l;
end;

function IsPathDelimiter(Path: String): Boolean;
begin
  IsPathDelimiter := Path[Length(Path)] = '\';
end;

end.