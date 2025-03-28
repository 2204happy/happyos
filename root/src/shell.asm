bits 16


;init
mov ax,cs
mov ds,ax
mov es,ax

call getbindir
mov si,loadedmsg
call print
jmp main


print:
  mov ah,0xe
  .loop mov al,[si]
    or al,al
    jz .loopend
    int 0x10
    cmp al,0xa
    jne .nonewline
    mov al,0xd
    int 0x10
    .nonewline inc si
    jmp .loop
  .loopend ret



main:
  call entercommand
  call interpretcommand
  jmp main

entercommand:
  mov si,entercommandstring
  call print
  mov bx,0x5600;where the command is stored
  .loop mov ah,0x0
    int 0x16
    or al,al
    jz .loop
    cmp al,0xd
    je .endloop
    cmp al,0x8
    je .dobackspace
    cmp al," "
    je .dospace
    mov ah,0xe
    mov [bx],al
    inc bx
    int 0x10
    jmp .loop
  .endloop mov [bx],byte 0x0
  inc bx
  mov [bx],byte 0x0
  mov si,newline
  call print
  ret
  .dobackspace cmp bx,0x5600
    je .loop
    dec bx
    mov [bx],byte 0x0
    mov ah,0xe
    mov al,0x8
    int 0x10
    mov al," "
    int 0x10
    mov al,0x8
    int 0x10
    jmp .loop
  .dospace mov ah,0xe
    int 0x10
    mov [bx],byte 0x0
    inc bx
    jmp .loop

interpretcommand:
  mov si,0x5600
  mov al,[si]
  or al,al
  jnz .noskip
  ret
  .noskip mov cx,word commands;which command it is being compared to
  .masterloop mov bx,cx;load pointer to somewhere in commands table into bx
    mov bx,[bx]
    or bx,bx;if its zero go to the end of the loop (no commands were found)
    jz .endmasterloop
    mov si,0x5600;where the command is in memory
    .minorloop mov al,[bx]
      mov ah,[si]
      cmp ah,al;if the characters are different than expected exit the minor loop and try the next command
      jne .endminorloop
      or ah,al;if they are both zero and were the same, run the command
      jz .runcommand
      ;increment both pointers to the strings
      inc si
      inc bx
      jmp .minorloop
    .endminorloop add cx,0x4;go to next byte (next command to try)
    jmp .masterloop
    .endmasterloop call dorun
      ret
    

  .runcommand add cx,0x2
    mov bx,cx
    inc si;so that si is pointing to the begining of the argument
    call [bx]
    ret


dorun:
  ;first try the bin directory
  mov dx,[bindir]
  mov si,0x5600
  mov ah,0x1
  int 0x20
  cmp cl,0x0
  je .run
    mov si,0x5600
    call resolvedir
    cmp cl,0x0
    je .run
    mov si,unknowncmd
    call print
    ret
  .run mov ax,0x1000
    mov es,ax
    mov ah,0x3
    mov di,0x0000
    int 0x20
    mov ax,cs
    mov es,ax
    mov ah,0x5
    mov si,0x5600
    mov cx,0x1000
    mov dx,[curdir]
    int 0x20
    mov ax,cs
    mov es,ax
    ret

chdir:
  mov ch,0x0
  call resolvedir
  cmp cl,0x1
  je .validdir
    mov si,nosuchdir
    call print
    ret
  .validdir mov [curdir],dx
    ret

resolvedir:
  mov dx,[curdir]
  mov ah,0x8
  int 0x20
  ret


getbindir:
  mov ah,0x1
  mov si,binstr
  mov dx,0x0
  int 0x20
  cmp cl,0x1
  jne .nobindir
  mov [bindir],dx
  ret
  .nobindir mov si,nobindirstr
  call print
  ret


doshutdown:
  mov ax,0x5301
  mov bx,0x0
  int 0x15
  mov ax,0x530e
  mov bx,0x0
  mov cx,0x0102
  int 0x15
  mov ax, 0x5307
  mov cx, 0x3
  mov bx, 0x1
  int 0x15

doreboot:
  call clear
  jmp 0x7c00

clear:
  mov ah,0x0
  mov al,0x3
  int 0x10
  ret

unknowncmd: db "No such command or file",0xa,0x0
loadedmsg: db "Loaded!",0xa,0x0
newline: db 0xa,0x0
entercommandstring: db ">",0x0
commands: dw shutdownstring,doshutdown,rebootstring,doreboot,clearstring,clear,cdstring,chdir,0x0
cdstring: db "cd",0x0
shutdownstring: db "shutdown",0x0
rebootstring: db "reboot",0x0
clearstring: db "clear",0x0
nosuchdir: db "No such directory",0xa,0x0
curdir: dw 0x0
bindir: dw 0x0
binstr: db "bin",0x0
nobindirstr: db "No binaries directory found!",0xa,0x0
