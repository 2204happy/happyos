print equ 0x6000
loadfile equ 0x6002
arg1 equ 0x5ffa
resolvedir equ 0x600e
returnstatus equ 0x5ff8

org 0xa000
bits 16


mov ax,0x1000
mov es,ax
mov bx,[arg1]
mov [bx],word 0x0000
call [resolvedir]
mov bx,[returnstatus]
mov dl,[bx]
cmp dl,byte 0x0
jne nofile

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


nofile:
  mov si,fnfstr
  call [print]
end: mov ax,0x0
  mov es,ax
  ret
  
waitforpress: pusha
  mov si,more
  call [print]
  mov ah,0x0
  int 0x16
  cmp ah,0x1
  jne .noesc
    mov [leaving],byte 0x1
    popa
    ret
  .noesc mov si,spaces
  call [print]
  dec byte [rowcount]
  popa
  ret

fnfstr: db "long: File not found",0x0
rowcount: db 0x0
colcount: db 0x0
leaving: db 0x0
more: db "Press any key to view more, or esc to quit",0x0
spaces: db 0xd,"                                          ",0xd,0x0
