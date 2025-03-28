bits 16

mov si,hellostring
call print
mov ah,0x6
int 0x20

print: mov ah,0xe
  .printLoop mov al,[si]
    cmp al,0x0
    je .end
    int 0x10
    inc si
    jmp .printLoop
  .end ret


hellostring: db "Hi!!!!!!",0xa,0xd,0x0
