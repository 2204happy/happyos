org 0xa000
bits 16

mov ax, cs
mov ds, ax
mov es,ax
cli
mov si,hellostring
call [0x6000]
ret
hellostring: db "GoodBYE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",0x0
