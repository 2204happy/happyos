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
mov ah,0xe
mainloop: cmp [es:si],byte 0x0
  je end
  cmp [colcount],byte 0x50
  jne .neol
    mov [colcount],byte 0x0
    inc byte [rowcount]
    cmp byte [rowcount],0x18
    jne .neol
    call waitforpress
    cmp [leaving],byte 0x0
    jne end
  .neol cmp [es:si],byte 0xa
  jne .nnl
    mov al,0xd
    int 0x10
    mov al,0xa
    int 0x10
    mov [colcount],byte 0xff
    inc byte [rowcount]
    cmp byte [rowcount],0x18
    jne .np
    call waitforpress
    cmp [leaving],byte 0x0
    jne end
    jmp .np
  .nnl mov al,[es:si]
  int 0x10
  .np inc si
  inc byte [colcount]
  jmp mainloop
  
waitforpress: push es
  pusha
  mov ax,cs
  mov es,ax
  mov si,more
  call print
  mov ah,0x0
  int 0x16
  cmp ah,0x1
  jne .noesc
    mov si,newline
    call print
    mov [leaving],byte 0x1
    popa
    pop es
    ret
  .noesc mov si,spaces
  call print
  dec byte [rowcount]
  popa
  pop es
  ret
  
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
    
end: mov ah,0x6
  int 0x20

print: mov ah,0xe
  .printLoop mov al,[es:si]
    cmp al,0x0
    je .end
    int 0x10
    inc si
    jmp .printLoop
  .end ret
  
fnfMessage: db "long: File not found",0xa,0xd,0x0
isDirMessage: db "long: Is a directory",0xa,0xd,0x0
rowcount: db 0x0
colcount: db 0x0
leaving: db 0x0
more: db "Press any key to view more, or esc to quit",0x0
spaces: db 0xd,"                                          ",0xd,0x0
newline: db 0xa,0xd,0x0
