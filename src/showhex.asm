org 0xa000
bits 16

mov ax, cs
mov ds, ax
mov es,ax
cli


mov ax,0x1000
mov es,ax
mov bx,[0x5ffa]
mov [bx],word 0x0000
call [0x600e]
mov bx,word [0x5ff8]
mov dl,[bx]
;add al,0x30
;mov ah,0xe
;int 0x10
;sub ah,0x30
cmp dl,byte 0x0
jne quit
mov ah,0x0
mov cx,ax
shl cx,0x9
mov dx,0x180
mov si,0x0000
loop: mov al,[es:si]
  mov bl,al
  and al,0xf0
  and bl,0x0f
  shr al,0x4
  add al,0x30
  add bl,0x30
  cmp al,0x3a
  jb .dontaddhigh
  add al,0x7
  .dontaddhigh cmp bl,0x3a
  jb .dontaddlow
  add bl,0x7
  .dontaddlow mov ah,0xe
  int 0x10
  mov al,bl
  int 0x10
  mov al," "
  int 0x10
  inc si
  dec cx
  dec dx
  dec byte [inlinetogo]
  cmp cx,0x0
  je done
  cmp [inlinetogo],byte 0x0
  jne .chkdx
  mov ah,0xe
  mov al,0xa
  int 0x10
  mov al,0xd
  int 0x10
  mov [inlinetogo],byte 0x10
  .chkdx cmp dx,0x0
  jne loop
  mov [tmp],si
  mov si,more
  call [0x6000]
  mov si,[tmp]
  mov ah,0x0
  int 0x16
  cmp al,0x1b
  je done
  mov ah,0xe
  mov al,0xd
  int 0x10
  mov dl,0x10
  jmp loop
done: mov ax,0x0
mov es,ax
ret

quit: mov si,nofilemsg
call [0x6000]
jmp done

nofilemsg: db "No file found (inprg)",0x0
inlinetogo: db 0x10
more: db "Press any key to view more, or esc to quit",0x0
tmp: dw 0x0
