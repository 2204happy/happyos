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

mov ah,0x2
int 0x20

mov ch,0x0
shl cx,0x9
mov dx,0x180
mov si,0x0000

loop: 
  mov al,[es:si]
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
  push si
  mov si,more
  call print
  pop si
  mov ah,0x0
  int 0x16
  cmp al,0x1b
  je done
  mov ah,0xe
  mov al,0xd
  int 0x10
  mov dl,0x10
  jmp loop

fileNotFound:
  mov ax,cs
  mov es,ax
  cmp cl,0x1
  je .isDirectory
    mov si,fnfMessage
    call print
    jmp done
  .isDirectory mov si,isDirMessage
    call print
    
done:
  mov si,newline
  call print
  mov ah,0x6
  int 0x20

print:
  mov ah,0xe
  .printLoop mov al,[si]
    cmp al,0x0
    je .end
    int 0x10
    inc si
    jmp .printLoop
  .end ret

fnfMessage: db "showhex: File not found",0x0
isDirMessage: db "showhex: Is a directory",0x0
inlinetogo: db 0x10
more: db "Press any key to view more, or esc to quit",0x0
newline: db 0xa,0xd,0x0
