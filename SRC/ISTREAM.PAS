{$A+,B-,D+,E+,F-,G+,I-,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
unit IStream;

interface

uses Objects, Dos, ITypes, IConst;


const
  BUFFER_SIZE = 32768;
  IMG_BUF_SIZE = BUFFER_SIZE div 512;
  IMAGE_PIECE = 720000000 div 512;

type

  { Image Stream }

  PImageStream = ^TImageStream;
  TImageStream = object(TStream)

  private
    FImageName: PString;
    FOpenMode: Word;
    FStream: PStream;
    FStreamCount: Byte;
    FSize: Longint;
    FPosition: Longint;
    FCurrentStream: Integer;

    FBeginBuffer: Longint;
    FEndBuffer: Longint;
    FBuffer: Pointer;

    function GetName(ImageName: String; Number: Byte): String;
    procedure SetCurrentStream;
    procedure SetStatus;

    procedure ReadBuffer(SectorNo: Longint);
    procedure WriteBuffer;

  public

    constructor Init(ImageName: FNameStr; Mode: Word);
    destructor Done; virtual;
    procedure WriteSector(var Buf);
    procedure Write(var Buf; Count: Word); virtual;
    procedure Read(var Buf; Count: Word); virtual;
    procedure Seek(Pos: Longint); virtual;
    function GetSize: Longint; virtual;
    function GetPos: Longint; virtual;
    procedure Flush; virtual;
    procedure Reset;

  end;


  { IDE Stream }

const
  fBusyCheck    = 1;
  fHazardCheck  = 2;
  fReadyCheck   = 4;
  fDataCheck    = 8;


type

  PIDEStream = ^TIDEStream;
  TIDEStream = object(TStream)

    FDrive: TDrive;
    FPosition: Longint;
    FSize: Longint;

    DriveStatus: Byte;
    Flags: Word;
    DriveFlags: Byte;

    constructor Init(Drive: TDrive; Mode: Word);
    procedure Read(var Buf; Count: Word); virtual;
    procedure Seek(Pos: Longint); virtual;
    procedure SeekDrive(Pos: Longint);
    procedure SendCommand(Command: Byte);

    function GetSize: Longint; virtual;
    function GetPos: Longint; virtual;
    procedure Identify(var Buf);
  end;



  { x13 Stream }

  TReadPacket = packed record
    Size: Byte;
    Reserved: Byte;
    Count: Word;
    Buffer: Pointer;
    SectorL: Longint;
    SectorH: Longint;
  end;

  TDriveParams = packed record
    Size: Word;
    Flags: Word;
    Cylinders: Longint;
    Heads: Longint;
    Sectors: Longint;
    TotalSectorsL: Longint;
    TotalSectorsH: Longint;
    BytesPerSector: Word;
  end;

  Px13Stream = ^Tx13Stream;
  Tx13Stream = object(TStream)
  private
    FDrive: Byte;
    FPosition: Longint;
    FSize: Longint;
    FReadPacket: TReadPacket;

  public
    DriveParams: TDriveParams;

    constructor Init(Drive: Byte; Mode: Word);
    procedure Identify;

    procedure Read(var Buf; Count: Word); virtual;
    procedure Write(var Buf; Count: Word); virtual;
    procedure SeekDrive(Pos: Longint);

    procedure Seek(Pos: Longint); virtual;
    function GetSize: Longint; virtual;
    function GetPos: Longint; virtual;

  end;

implementation


{ TImageStream }

constructor TImageStream.Init;
var
  SRec: SearchRec;
  i: Integer;

begin
  inherited Init;
  FImageName := NewStr(ImageName);
  FOpenMode := Mode;
  FPosition := 0;
  FCurrentStream := 0;
  FStreamCount := 0;
  FSize := 0;

  case Mode of
    stCreate: FStream := New(PBufStream, Init(GetName(FImageName^, FCurrentStream), FOpenMode, BUFFER_SIZE));

    stOpen: begin
      i := 0;
      FindFirst(GetName(FImageName^, i), Archive, SRec);
      while DosError = 0 do begin
        inc(i);
        Inc(FSize, SRec.Size div 512);
        FindFirst(GetName(FImageName^, i), Archive, SRec);
      end;
      FStreamCount := i;
      FStream := New(PBufStream, Init(GetName(FImageName^, FCurrentStream), FOpenMode, BUFFER_SIZE));
    end;
  end;

  FBeginBuffer := -1;
  FEndBuffer := -1;
  GetMem(FBuffer, BUFFER_SIZE);

  if FSize > 0 then
    ReadBuffer(0);

  SetStatus;
end;


destructor TImageStream.Done;
begin
  Dispose(FStream, Done);
  DisposeStr(FImageName);
  FreeMem(FBuffer, BUFFER_SIZE);
  inherited Done;
end;

function TImageStream.GetName;
var
  s: String;
  i: Integer;
begin
  Str(Number:3, s);
  for i := 1 to 2 do
    if s[i] = #32 then
      s[i] := #48;
  GetName := ImageName + '.' + s;
end;

procedure TImageStream.SetCurrentStream;
begin
  if FCurrentStream <> (FPosition div IMAGE_PIECE) then begin
    Dispose(FStream, Done);
    FCurrentStream := FPosition div IMAGE_PIECE;
    FStream := New(PBufStream, Init(GetName(FImageName^, FCurrentStream), FOpenMode, BUFFER_SIZE));
    if FCurrentStream > FStreamCount then
      FStreamCount := FCurrentStream;
  end;
end;

procedure TImageStream.Write;
var
  i: Integer;

begin
  i := 0;
  while (i < Count) and (Status = stOk) do begin
    SetCurrentStream;

    FStream^.Write(TByteArray(Buf)[i * 512], 512);

    SetStatus;
    if FPosition = FSize then
      inc(FSize);
    Inc(FPosition);
    Inc(i);
  end;
end;



procedure TImageStream.WriteSector;
begin
  if (FPosition < FBeginBuffer) or (FPosition > FEndBuffer) then begin
    WriteBuffer;
    ReadBuffer(FPosition);
  end;
  Move(Buf, TByteArray(FBuffer^)[(FPosition - FBeginBuffer) * 512], 512);
end;



procedure TImageStream.ReadBuffer;
var
  ReadSectors: Longint;

begin
  Seek(SectorNo);

  if SectorNo + IMG_BUF_SIZE > FSize then
    ReadSectors := FSize - SectorNo
  else
    ReadSectors := IMG_BUF_SIZE;

  Read(FBuffer^, ReadSectors);

  if Status = stOk then begin
    FBeginBuffer := SectorNo;
    FEndBuffer := SectorNo + ReadSectors - 1;
  end;
end;

procedure TImageStream.WriteBuffer;
begin
  Seek(FBeginBuffer);
  Write(FBuffer^, FEndBuffer - FBeginBuffer + 1);
end;



procedure TImageStream.Read;
var
  i: Integer;
  p: Pointer;

begin
  i := 0;
  while (i < Count) and (Status = stOk) do begin
    SetCurrentStream;

    p := Addr(TByteArray(Buf)[i * 512]);
    FStream^.Read(p^, 512);

    SetStatus;
    Inc(FPosition);
    Inc(i);
  end;
end;

procedure TImageStream.Seek;
begin
  FPosition := Pos;
  if FCurrentStream <> FPosition div IMAGE_PIECE then begin
    Dispose(FStream, Done);
    FCurrentStream := FPosition div IMAGE_PIECE;
    FStream := New(PBufStream, Init(GetName(FImageName^, FCurrentStream), FOpenMode, BUFFER_SIZE));
    if FCurrentStream > FStreamCount then
      FStreamCount := FCurrentStream;
  end;
  FStream^.Seek((FPosition mod IMAGE_PIECE) * 512);
  SetStatus;
end;

function TImageStream.GetSize;
begin
  GetSize := FSize;
end;

function TImageStream.GetPos;
begin
  GetPos := FPosition;
end;

procedure TImageStream.Flush;
begin
  FStream^.Flush;
  SetStatus;
end;

procedure TImageStream.Reset;
begin
  FStream^.Reset;
  SetStatus;
end;

procedure TImageStream.SetStatus;
begin
  Status := FStream^.Status;
  ErrorInfo := FStream^.ErrorInfo;
{  if FImagePiece = 0 then
    Status := stError;}
end;


{ TIDEStream }

constructor TIDEStream.Init;
begin
  inherited Init;
  FDrive := Drive;
  FPosition := 0;
  FSize := 0;
end;


procedure TIDEStream.Seek;
begin
  FPosition := Pos;
end;




procedure TIDEStream.SeekDrive; assembler;
asm
  push ds
  push es

  push es
  pop  ds                          { ustawienie ds na segment danych obiektu }

  mov   dx, [FDrive.IDE]                         { ustawienie dysku twardego }
  add   dx, 2

  lea   di, [FPosition]

  db    66h
  mov   ax, [di]                      { wpisanie do eax zawartosci FPosition }

  mov   cx, 3

  @PutData:                          {  wpisanie numeru sektora do kolejnych }
                                     {  portow: 1F3 1F4 1F5                  }
  inc   dx
  out   dx, al

  db    66h
  shr   ax, 8

  loop  @PutData

  inc   dx
  or    al, [FDrive.Device]        { ustawienie master/slave oraz trybu LBA }
  out   dx, al


@SetCommand:

  inc   dx
  mov   al, 70h  { seek }
  out   dx, al

@BusyCheck:
  in    al, dx
  test  al, 10000000b                     { sprawdzenie czy dysk jest zajety }
  jnz  @BusyCheck;

@SeekCheck:
  in    al, dx
  test  al, 00010000b         { sprawdzenie zakonczono pozycjonowanie glowic }
  jz  @SeekCheck;


  db    66h
  mov   ax, word ptr [Pos]
  db    66h
  mov   word ptr [FPosition], ax

@Exit:
  pop   es
  pop   ds

end;










procedure TIDEStream.Read;
var
  IDrive: TDrive;
  IFlags: Word;
  IStatus: Word;
  IErrorInfo: Word;
  IPosition: Longint;
  IDriveFlags: Byte;

begin
  IDrive := FDrive;
  IFlags := Flags;
  IPosition := FPosition;

  asm
    push ds                     { zapisanie uzywanych rejestrow segmentowych }
    push es

    push es
    pop  ds                        { ustawienie ds na segment danych obiektu }

  @StartRead:


    mov   dx, [IDrive.IDE]                { sprawdzenie czy dysk jest gotowy }
    add   dx, 7
    in    al, dx
    test  al, 01000000b
    jz    @NoData


    mov   dx, [IDrive.IDE]                       { ustawienie dysku twardego }
    add   dx, 2

    mov   al, 1                      { ustawienie ilosci sektorow do odczytu }
    out   dx, al


    db    66h
    mov   ax, word ptr [IPosition]    { wpisanie do eax zawartosci FPosition }

    mov   cx, 3

    @PutData:                        {  wpisanie numeru sektora do kolejnych }
                                     {  portow: xF3 xF4 xF5                  }
    inc   dx
    out   dx, al

    db    66h
    shr   ax, 8

    loop  @PutData

    inc   dx
    or    al, [IDrive.Device]       { ustawienie master/slave oraz trybu LBA }
    out   dx, al


  @SetCommand:

    inc   dx
    mov   al, cmdReadSector                     { polecenie odczytu sektorow }
    out   dx, al


    test  [IFlags], fBusyCheck
    jz    @DataCheck

  @BusyCheck:

    mov   cx, 0FFFFh

  @BigLoop:
    push  cx
    mov   cx, 0FFFFh

  @BusyWait:
    in    al, dx
    test  al, 10000000b
    loopnz @BusyWait
    pop cx
    loopnz @BigLoop

    test  al, 10000000b
    jnz    @NoData


  @DataCheck:

    test  [IFlags], fDataCheck
    jz    @ReadData

  @WaitForData:                           { oczekiwanie na dane z kontrolera }

    mov   cx, 0FFFFh
    @DataWait:

    in    al, dx
    test  al, 00001000b
    loopz @DataWait

    test  al, 00001000b
    jz    @NoData


  @ReadData:

    mov   dx, [IDrive.IDE]                   { ustawienie rejestrow do odczytu }
    les   di, Buf
    cld

    mov   cx, 128

  @GetData:
    db    66h                 { odczyt danych z wykorzystaniem instrukcji i386 }
    in    ax, dx
    db    66h
    stosw
    loop  @GetData


  @SetResult:                 { ustawienie odczytu }

    mov   dx, [IDrive.IDE]
    add   dx, 7
    in    al, dx

  @ErrorCheck:
    test  al, 00000001b
    jnz   @NoData

  @HazardCheck:
    test  [IFlags], fHazardCheck
    jz    @ReadyCheck

    test  al, 00100000b
    jnz    @NoData

  @ReadyCheck:
    test  [IFlags], fReadyCheck
    jz    @SetOk

    test  al, 01000000b
    jz    @NoData

  @SetOk:
    mov   [IStatus], stOk
    mov   [IDriveFlags], al
    jmp   @Exit


  @NoData:
    mov   [IDriveFlags], al
    mov   [IStatus], stReadError

    mov   dx, [IDrive.IDE]
    inc   dx
    in    al, dx
    mov   [IErrorInfo], ax

  @Exit:

    pop   es
    pop   ds
  end;

  Status := IStatus;
  ErrorInfo := IErrorInfo;
  DriveFlags := IDriveFlags;
end;




procedure TIDEStream.Identify;
var
  IDrive: TDrive;
  IFlags: Word;
  IStatus: Word;
  IErrorInfo: Word;

begin
  IDrive := FDrive;
  IFlags := Flags;

  asm
    push ds                       { zapisanie uzywanych rejestrow segmentowych }
    push es

    push es
    pop  ds                          { ustawienie ds na segment danych obiektu }

  @StartIdentify:

    mov   dx, [IDrive.IDE]                         { ustawienie dysku twardego }
    add   dx, 2

    mov   ax, 1                             { odczyt danych dlugosci 1 sektora }
    out   dx, al

    add   dx, 4
    mov   al, [IDrive.Device]         { ustawienie master/slave oraz trybu LBA }
    out   dx, al


  @SetCommand:

    inc   dx
    mov   al, cmdIdentifyDrive                       { polecenie identyfikacji }
    out   dx, al

    test  [IFlags], fBusyCheck
    jz    @WaitForData


  @BusyCheck:

    mov   cx, 0FFFFh
    @BusyWait:

    in    al, dx
    test  al, 10000000b
    loopnz @BusyWait

    test  al, 10000000b
    jnz    @NoData


  @WaitForData:                             { oczekiwanie na dane z kontrolera }

    mov   cx, 0FFFFh
    @DataWait:

    in    al, dx
    test  al, 00001000b
    loopz @DataWait

    test  al, 00001000b
    jz    @NoData


  @ReadData:

    mov   dx, [IDrive.IDE]                   { ustawienie rejestrow do odczytu }
    les   di, Buf
    cld

    mov   cx, 128

  @GetData:
    db    66h                 { odczyt danych z wykorzystaniem instrukcji i386 }
    in    ax, dx
    db    66h
    stosw
    loop  @GetData


  @SetResult:                 { ustawienie odczytu }

    mov   dx, [IDrive.IDE]
    add   dx, 7
    in    al, dx

  @ErrorCheck:
    test  al, 00000001b
    jnz   @NoData

  @HazardCheck:
    test  [IFlags], fHazardCheck
    jz    @ReadyCheck

    test  al, 00100000b
    jnz    @NoData

  @ReadyCheck:
    test  [IFlags], fReadyCheck
    jz    @SetOk

    test  al, 01000000b
    jz    @NoData

  @SetOk:
    mov   [IStatus], stOk
    jmp   @Exit


  @NoData:
    mov   [IStatus], stReadError

    mov   dx, [IDrive.IDE]
    inc   dx
    in    al, dx
    mov   [IErrorInfo], ax

  @Exit:

    pop   es
    pop   ds
  end;


  FSize := TDriveInfo(Buf).TotalSectors;
  Flags := IFlags;
  ErrorInfo := IErrorInfo;
  Status := IStatus;
end;


function TIDEStream.GetSize;
begin
  GetSize := 0;
end;

function TIDEStream.GetPos;
begin
  GetPos := FPosition;
end;

procedure TIDEStream.SendCommand(Command: Byte);
var
  IDrive: TDrive;

begin
  IDrive := FDrive;

  asm
    push ds                       { zapisanie uzywanych rejestrow segmentowych }

    push es
    pop  ds                          { ustawienie ds na segment danych obiektu }

  @SelectDrive:

    mov   dx, [IDrive.IDE]
    add   dx, 6
    mov   al, [IDrive.Device]
    out   dx, al


  @SetCommand:

    inc   dx
    mov   al, [Command]
    out   dx, al



  @BusyCheck:

    mov   cx, 0FFFFh
    @BusyWait:

    in    al, dx
    test  al, 10000000b
    loopnz @BusyWait

    pop   ds
  end;
end;














{ Tx13Stream }


constructor Tx13Stream.Init;
begin
  inherited Init;
  FDrive := Drive;
  FPosition := 0;
  FReadPacket.Size := SizeOf(FReadPacket);
  DriveParams.Size := SizeOf(DriveParams);

end;

procedure Tx13Stream.Identify; assembler;
asm

  push   ds

  push   es
  pop    ds

  mov    dl, [FDrive]
  lea    si, [DriveParams]
  mov    ah, 48h
  int    13h

  pop    ds
end;

function Tx13Stream.GetSize;
begin
  GetSize := DriveParams.TotalSectorsL;
end;

function Tx13Stream.GetPos;
begin
  GetPos := FPosition;
end;

procedure Tx13Stream.Seek;
begin
  FPosition := Pos;
end;


procedure Tx13Stream.SeekDrive;
begin
  FPosition := Pos;
  FReadPacket.SectorL := FPosition;
  asm
    push  ds                       { zapisanie uzywanych rejestrow segmentowych }

    push  es
    pop   ds                          { ustawienie ds na segment danych obiektu }

    lea   si, [FReadPacket]
    mov   dl, [FDrive]
    mov   ah, 47h
    int   13h

    mov   [Status], ax
    pop   ds
  end;
end;

procedure Tx13Stream.Read;
begin
  FReadPacket.SectorL := FPosition;
  FReadPacket.Count := Count;
  FReadPacket.Buffer := @Buf;

  asm
    push  ds                       { zapisanie uzywanych rejestrow segmentowych }

    push  es
    pop   ds                          { ustawienie ds na segment danych obiektu }

    lea   si, [FReadPacket]
    mov   dl, [FDrive]
    mov   ah, 42h
    int   13h

    mov   [Status], ax
    pop   ds
  end;

  Inc(FPosition, Count);
end;


procedure Tx13Stream.Write;
begin
  FReadPacket.SectorL := FPosition;
  FReadPacket.Count := Count;
  FReadPacket.Buffer := @Buf;

  asm
    push  ds                       { zapisanie uzywanych rejestrow segmentowych }

    push  es
    pop   ds                          { ustawienie ds na segment danych obiektu }

    lea   si, [FReadPacket]
    mov   dl, [FDrive]
    mov   ax, 4301h
    int   13h

    mov   [Status], ax
    pop   ds
  end;

  Inc(FPosition, Count);
end;




end.
