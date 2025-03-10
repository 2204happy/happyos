org 0x7c00
bits 16

mov ax, cs
mov ds, ax
mov es,ax
cli
mov [0x5fff],dl
fninput: mov si,bootmsg
call print
mov bx,0x7e00
mov ah,0x2
mov al,0x4
mov ch,0x0
mov cl,0x2
mov dh,0x0

mov dl,[0x5fff]
int 0x13
jmp 0x7e00
hlt

print:
  mov ah,0xe
  loop: mov al,[si]
    or al,al
    jz loopend
    int 0x10
    inc si
    jmp loop
  loopend: ret

bootmsg: db 0xa,0xd,"Loading OS...",0xa,0xd,0x0

times 510 - ($ - $$) db 0
db 0x55
db 0xaa

