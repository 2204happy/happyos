org 0x7c00
bits 16

mov ax, cs
mov ds, ax
mov es,ax
cli
mov si,voltypemsg
call print
bginput: mov ah,0x0
  int 0x16
  cmp al,"f"
  je floppy
  cmp al,"d"
  je hdd
  jmp bginput
floppy: mov [0x5fff],byte 0x0
  jmp fninput
hdd: mov [0x5fff],byte 0x80
fninput: mov si,bootmsg
call print
mov bx,0x7e00
mov ah,0x2
mov al,0x2
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

voltypemsg: db "Are you booting from a (F)loppy or a Hard (D)rive?",0x0
bootmsg: db 0xa,0xd,"Loading OS...",0xa,0xd,0x0

times 510 - ($ - $$) db 0
db 0x55
db 0xaa

