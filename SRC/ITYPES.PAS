unit ITypes;

interface

type

  PLongint = ^Longint;

  { TConfig }

  TGeneralOptionsRec = packed record
    DesktopFlag: Word;
  end;

  TDetectOptionsRec = packed record
    DetectFlag: Word;
    WaitFlag: Word;
    CheckFlag: Word;
    OtherFlag: Word;
  end;

  TProjectOptionsRec = packed record
    ProjectsDirectory: String[80];
    ImagesDirectory: String[80];
    CreateSubDirectory: Word;
  end;

  TConfigRec = packed record
    DetectOptions: TDetectOptionsRec;
    GeneralOptions: TGeneralOptionsRec;
    ProjectOptions: TProjectOptionsRec;
  end;




  { TIDEStream }

  PDriveInfo = ^TDriveInfo;
  TDriveInfo = packed record

    GeneralConfig: Word;            {00h	WORD	general configuration}
    Cylinders: Word;                {02h	WORD	number of logical cylinders}
    Reserved1: Word;                {04h	WORD	reserved}
    Heads: Word;                    {06h	WORD	number of logical heads}
    BytesPerTrack: Word;            {08h	WORD	vendor-specific}
    BytesPerSector: Word;           {0Ah	WORD	vendor-specific}
    Sectors: Word;                  {0Ch	WORD	number of logical sectors}
    VendorSpec1: Word;              {0Eh	WORD	vendor-specific}
    VendorSpec2: Word;              {10h	WORD	vendor-specific}
    VendorSpec3: Word;              {12h	WORD	vendor-specific}
    SerialNo: array[1..20] of Char; {14h     10 WORDs	serial number, no serial number
                                                        if first word is 0000h else blank-padded ASCII serial number}
    CtrlType: Word;                 {28h	WORD	vendor-specific [controller type]}
    CtrlBufSize: Word;              {2Ah	WORD	vendor-specific [controller buffer size in 512-byte sectors]}
    ECCBytes: Word;                 {2Ch	WORD	number of vendor-specific (usually ECC) bytes on Read/Write Long}
    Firmware: array [1..8] of Char; {2Eh      4	WORDs	firmware revision, no revision number
                                                        if first word is 0000h else blank-padded ASCII revision number}
    Model: array [1..40] of Char;   {36h     20	WORDs	model number
                                                        no model number if first word is 0000h
                                                        else blank-padded ASCII model string}
    RWMultiple: Word;               {5Eh	WORD	read/write multiple support
                                                        bits 7-0: maximum number of sectors per block supported
                                                        00h if read/write multiple not supported}
    Reserved2: Word;                {60h	WORD	reserved (0) able to do doubleword transfers if nonzero ???}
    Capabilities: Word;             {62h	WORD	capabilities (see #P088)}
    SecurityMode: Word;             {64h	WORD	security mode
		                                        bit 15: security-mode feature set supported
                                                        bits 14-8: maximum number of passwords supported}
    PIODataTransfer: Word;          {66h	WORD	PIO data transfer cycle timing}
    DMADataTransfer: Word;          {68h	WORD	single-word DMA data transfer cycle timing}
    Validity: Word;                 {6Ah	WORD	field validity
		                                        bit 0: offsets 6Ch-73h valid
		                                        bit 1: offsets 80h-8Dh valid}
    LogicalCylinders: Word;         {6Ch	WORD	logical cylinders in current translation mode}
    LogicalHeads: Word;             {6Eh	WORD	logical heads in current translation mode}
    LogicalSectors: Word;           {70h	WORD	logical sectors per track in current translation mode}
    SectorsCapacity: Longint;       {72h      2	WORDs	current capacity in sectors (excluding device-specific uses)}
    RWMultipleCount: Word;          {76h	WORD	multiple-sector count for read/write multiple command}
    TotalSectors: Longint;          {78h      2	WORDs	total number of user-addressable sectors (LBA mode)
		                                        00000000h if LBA mode not supported}
    DMATransferModes: Word;         {7Ch	WORD	single-word DMA transfer modes
                                                        low byte is bitmap of supported modes (bit 0 = mode 0, etc.)
		                                        high bytes is bitmap of active mode (bit 8 = mode 0, etc.)}
    MWDMATransfer: Word;            {7Eh	WORD	multiword DMA transfer
		                                        low byte is bitmap of supported modes (bit 0 = mode 0, etc.)
		                                        high bytes is bitmap of active mode (bit 8 = mode 0, etc.)}
    PIOTransferModes: Word;         {80h	WORD	supported flow control PIO transfer modes}
    MinMWDMATransfer: Word;         {82h	WORD	minimum multiword DMA transfer cycle time}
    RecomendedMWDMA: Word;          {84h	WORD	recommended multiword DMA cycle time}
    MinPIOTransferNoFlow: Word;     {86h	WORD	minimum non-flow-control PIO transfer cycle time}
    MinPIOTransferRDY: Word;        {88h	WORD	minimum PIO transfer cycle time with IORDY}
    Cable: LongInt;                 {8Ah      2 WORDs	reserved for future PIO modes (0)}
    Reserved4: array[1..58] of Word;{8Eh     58 WORDs	reserved (0)}
    Vendor5: array[1..32] of Word;  {100h    32 WORDs	vendor-specific}
    Reserved5: array[1..96] of Word;{140h    96 WORDs	reserved (0)}
  end;


  PDrive = ^TDrive;
  TDrive = packed record
    IDE: Word;
    Device: Byte;
    DriveInfo: TDriveInfo;
  end;

  { TProject }

  TGeometryRec = packed record
    Mode: Byte;
    LBASupported: Boolean;
    AddressableSectors: Longint;
    Cylinders: Word;
    Sectors: Byte;
    Heads: Byte;
  end;

  TImageRec = packed record
    Prepared: Boolean;
  end;

  TProjectRec = packed record
    Header: Array[1..16] of Char;
    Name: String[8];
    Geometry: TGeometryRec;
    Image: TImageRec;
    DriveInfo: TDriveInfo;
    BadSectors: Longint;
    ReadSectors: Longint;
    Options: TProjectOptionsRec;
  end;

  TSectorsRec = packed record
    StartSector: Longint;
    EndSector: Longint;
  end;

implementation

end.