bits 16

.loop1 cmp [es:si],byte 0x0
  je .end1
  inc si
  jmp .loop1
.end1 inc si 

mov ah,0x8
int 0x20

cmp cl,0x0
jne fileNotFound

mov ax,cs
mov es,ax

mov bx,0x100
mov ah,0x0
.testloop cmp bx,0x300
  je .end
  mov [bx],ah
  inc ah
  inc bx
  jmp .testloop
.end mov si,0x100

mov ah,0xb
int 0x20

end:
  mov ah,0x6
  int 0x20

print: mov ah,0xe
  .printLoop mov al,[es:si]
    cmp al,0x0
    je .end
    int 0x10
    inc si
    jmp .printLoop
  .end ret
  
fileNotFound:
  mov ax,cs
  mov es,ax
  cmp cl,0x1
  je .isDirectory
    mov si,fnfMessage
    call print
    jmp end
  .isDirectory mov si,isDirMessage
    call print
    jmp end

fnfMessage: db "writetest: File not found",0xa,0xd,0x0
isDirMessage: db "writetest: Is a directory",0xa,0xd,0x0
