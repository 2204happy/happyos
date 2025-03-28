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
  mov ax,0x2000
  mov es,ax
  mov di,0x0
  mov ah,0x3
  int 0x20
  mov si,0x0
  call print
  jmp end

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

end:
  mov ah,0x6
  int 0x20

print: mov ah,0xe
  .printLoop mov al,[es:si]
    cmp al,0x0
    je .end
    int 0x10
    inc si
    cmp al,0xa
    jne .printLoop
    mov al,0xd
    int 0x10
    jmp .printLoop
  .end ret
  
fnfMessage: db "show: File not found",0xa,0x0
isDirMessage: db "show: Is a directory",0xa,0x0

