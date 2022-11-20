Unit IConst;


interface

uses
  ITypes;

const


  Primary = $1F0;
  Secondary = $170;
  Master = $E0;
  Slave = $F0;

  MasterCHS = $A0;
  SlaveCHS = $B0;

  cmdIdentifyDrive = $EC;
  cmdStandBy = $94;
  cmdReadSector = $20;
  cmdReadLongSector = $22;

  DriveList: Array[0..3] of TDrive = ((IDE: Primary; Device: MasterCHS),
                                      (IDE: Primary; Device: SlaveCHS),
                                      (IDE: Secondary; Device: MasterCHS),
                                      (IDE: Secondary; Device: SlaveCHS));

  DriveString: Array[0..3] of String[16] =
    ('Primary Master', 'Primary Slave', 'Secondary Master', 'Secondary Slave');


  ConfigFileName = 'IDE.CFG';

  MaxCHSCapacity = 16514064;

  ProjectHeader: array[1..16] of char = ('I','D','E',' ','P','R','O','J','E','C','T',' ',' ',' ',' ',' ');

implementation

end.