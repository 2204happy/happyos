idArray equ 0x1000
stringBuffer equ 0x2000

bits 16

mov ax,cs
mov es,ax

mov ah,0x7
mov di,idArray
int 0x20

mov bx,idArray

lsloop: mov dx,[bx]
  cmp dx,0x0
  je end
  mov ah,0x4
  mov di,stringBuffer
  int 0x20
  mov si,di
  call print
  mov si,newline
  call print
  add bx,0x2
  jmp lsloop
end:

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

newline: db 0xa,0xd,0x0

