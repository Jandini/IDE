Unit ICrt;

interface

function KeyPressed: Boolean;
function ReadKey: Char;

implementation

function KeyPressed: Boolean; assembler;
asm
  mov   ah, 1
  int   16h
  mov   al, 0
  je    @exit
  mov   al, 1
@exit:
end;

function ReadKey: Char; assembler;
asm
  xor   ah, ah
  int   16h
  jne   @exit
@exit:
end;

end.