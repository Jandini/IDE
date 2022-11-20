Unit IMap;

interface

uses Objects, Dos;

const
  MAP_BUF_SIZE = 32768;
  MAP_EXT = '.MAP';


type
  PMap = ^TMap;
  TMap = object(TObject)
  private
    FMapStream: PBufStream;
    FSize: Longint;
    FName: String;
    FBeginBuffer: Longint;
    FEndBuffer: Longint;
    FBuffer: Pointer;

    procedure ReadBuffer(SectorNo: Longint);
    procedure WriteBuffer;

  public
    constructor Init(Name: FNameStr);
    destructor Done; virtual;

    function GetSector(SectorNo: Longint): Byte;
    procedure SetSector(SectorNo: Longint; Value: Byte);
    procedure SetBlock(SectorNo: Longint; BlockSize, Value: Byte);


    function GetSize: Longint;
    procedure SetSize(Size: Longint);
    procedure Flush;
    procedure Clear;
  end;

implementation


constructor TMap.Init;
var
  Search: SearchRec;

begin
  inherited Init;
  FName := Name + MAP_EXT;
  FindFirst(FName, AnyFile - Directory, Search);
  if DosError = 0 then
    FMapStream := New(PBufStream, Init(FName, stOpen, MAP_BUF_SIZE))
  else
    FMapStream := New(PBufStream, Init(FName, stCreate, MAP_BUF_SIZE));

  FSize := FMapStream^.GetSize;
  FBeginBuffer := -1;
  FEndBuffer := -1;
  GetMem(FBuffer, MAP_BUF_SIZE);
  if FSize > 0 then
    ReadBuffer(0);
end;

destructor TMap.Done;
begin
  Dispose(FMapStream);
  FreeMem(FBuffer, MAP_BUF_SIZE);
  inherited Done;
end;

procedure TMap.Flush;
begin
  WriteBuffer;
  FMapStream^.Flush;
end;

function TMap.GetSector;
var
  Result: Byte;

begin
  if (SectorNo < FBeginBuffer) or (SectorNo > FEndBuffer) then
    ReadBuffer(SectorNo);

  GetSector := TByteArray(FBuffer^)[SectorNo - FBeginBuffer];
end;

procedure TMap.SetSector;
begin
  if (SectorNo < FBeginBuffer) or (SectorNo > FEndBuffer) then begin
    WriteBuffer;
    ReadBuffer(SectorNo);
  end;

  TByteArray(FBuffer^)[SectorNo - FBeginBuffer] := Value;
end;

procedure TMap.SetBlock;
var
  Rest: Longint;

begin

  if (SectorNo < FBeginBuffer) or (SectorNo > FEndBuffer) then begin
    WriteBuffer;
    ReadBuffer(SectorNo);
  end;

  if SectorNo + BlockSize <= FEndBuffer then
    FillChar(TByteArray(FBuffer^)[SectorNo - FBeginBuffer], BlockSize, Value)
  else begin
    Rest := (SectorNo + BlockSize) - FEndBuffer - 1;
    FillChar(TByteArray(FBuffer^)[SectorNo - FBeginBuffer], BlockSize - Rest , Value);
    WriteBuffer;
    ReadBuffer(SectorNo + (BlockSize - Rest));
    FillChar(TByteArray(FBuffer^)[0], Rest, Value);
  end;
end;

procedure TMap.ReadBuffer;
var
  ReadSectors: Longint;

begin
  FMapStream^.Seek(SectorNo);

  if SectorNo + MAP_BUF_SIZE > FSize then
    ReadSectors := FSize - SectorNo
  else
    ReadSectors := MAP_BUF_SIZE;

  FMapStream^.Read(FBuffer^, ReadSectors);

  if FMapStream^.Status = stOk then begin
    FBeginBuffer := SectorNo;
    FEndBuffer := SectorNo + ReadSectors - 1;
  end;
end;

procedure TMap.WriteBuffer;
begin
  FMapStream^.Seek(FBeginBuffer);
  FMapStream^.Write(FBuffer^, FEndBuffer - FBeginBuffer + 1);
end;


function TMap.GetSize;
begin
  GetSize := FSize;
end;

procedure TMap.SetSize;
var
  i, j, k: Longint;
begin
  if FSize < Size then begin
    FillChar(FBuffer^, MAP_BUF_SIZE, 0);
    FMapStream^.Seek(FSize);
    j := (Size - FSize);
    k := j div MAP_BUF_SIZE;
    for i := 1 to k do
      FMapStream^.Write(FBuffer^, MAP_BUF_SIZE);
    FMapStream^.Write(FBuffer^, j mod MAP_BUF_SIZE);
  end
  else begin
    FMapStream^.Seek(Size);
    FMapStream^.Truncate;
  end;
  FSize := FMapStream^.GetSize;
end;

procedure TMap.Clear;
var
  i, j: Longint;
begin
  FillChar(FBuffer^, MAP_BUF_SIZE, 0);
  FMapStream^.Seek(0);
  j := FSize div MAP_BUF_SIZE;
  for i := 1 to j do
    FMapStream^.Write(FBuffer^, MAP_BUF_SIZE);
  FMapStream^.Write(FBuffer^, FSize mod MAP_BUF_SIZE);
end;

end.