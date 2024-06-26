driveindex equ 0x5fff

org 0x7e00
bits 16

;init
mov ax, cs
mov ds, ax
mov es,ax
mov bp,ax
cli
mov [0x5ff8],word returnstatus
mov [0x5ffa],word arg1
mov [0x5ffc],word curdir
mov [0x6000],word print
mov [0x6002],word loadfile
mov [0x6004],word dorun
mov [0x6006],word doshow
mov [0x6008],word clear
mov [0x600a],word doshutdown
mov [0x600c],word doreboot
mov [0x600e],word resolvedir
call getdiskparams
call loadfs
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
dols:
  mov bx,0x4000;where the fs begins
  .loop mov ah,[bx]
    or ah,ah
    jz .end;if it reaches a zero it is at the end of the fs
    cmp ah,0x1
    je .noprint;skip the print if it is free space
    mov si,bx
    add si,0x3;move to see what its parent dir is
    mov dl,[si]
    cmp dl,[curdir];compare to current dir
    jne .noprint;don't print if it's in a different directory
    inc si;move to the begining of the file/directory name
    call print
    mov si,newline;print a newline
    call print
    .noprint add bx,0x10
  jmp .loop
  .end mov dl,0x0
  ret

    
getdiskparams:
  mov dl,[driveindex]
  cmp dl,0x80
  jae .hd
  mov si,floppyboot
  call print
  ret
  .hd mov si,getdiskgeomsg
  call print
  mov dx,0x0
  mov es,dx
  mov ah,0x8;argument to get params
  mov dl,[driveindex];drive index
  mov di,0x0;get around buggy bioses
  int 0x13;call disk services
  and cl,0b00111111
  mov [sectorspertrack],cl
  inc dh
  mov [headsno],dh
  cmp ah,0x0
  je .cont
  mov si,errormsg
  call print
  jmp $
  .cont mov al,cl
  mul dh
  mov [hntspt],al
  mov si,donemsg
  call print
  ret
  
headsno: db 0x2
sectorspertrack: db 0x12
hntspt: db 0x24



loadfs:
  mov si,readfsmsg
  call print
  mov cl,0x6
  mov bx,0x4000
  mov ah,0x2
  mov al,0x1
  mov ch,0x0
  mov dh,0x0
  mov dl,[driveindex]
  int 0x13
  mov si,donemsg
  call print
  ret

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
    .endmasterloop mov si,0x5600
    call dorun
    cmp byte [returnstatus],0x0
    je .exit
    mov si,unknowncmd
    call print
    .exit ret
    

  .runcommand add cx,0x2
    mov bx,cx
    inc si;so that si is pointing to the begining of the argument
    call [bx]
    ret

loadfile:;argument1 for where to load to
  mov al,[si]
  or al,al
  jz .noargs
  mov bx,0x4000;where the fs begins
  mov cx,si;save the begining of the argument
  .loop mov dx,bx;save bx value
    mov ah,[bx]
    or ah,ah
    jz .end;if it reaches a zero it is at the end of the fs
    add bx,0x3
    mov al,[bx]
    cmp al,[curdir]
    jne .skipdircheck
    inc bx;move to the begining of the filename
    cmp ah,0x2
    jne .trydir;skip the test if it isn't a file
    mov si,cx;move start of argument string back into si
    call cmpstrings
    cmp byte [returnstatus],0x1
    je .load
    .trydir cmp ah,0x3
    jne .skipdircheck
    mov si,cx;move start of argument string back into si
    call cmpstrings
    cmp byte [returnstatus],0x1
    je .gotdir
    .skipdircheck mov bx,dx
    add bx,0x10
    jmp .loop
  .end mov [returnstatus],byte 0x1
    ret
  .load mov bx,dx
    inc bx
    mov cl,[bx]
    mov ah,0x0
    mov al,cl
    div byte [hntspt]
    mov ch,al
    mov al,ah
    mov ah,0x0
    div byte [sectorspertrack]
    mov dh,al
    mov cl,ah
    inc cl
    inc bx
    mov al,[bx];this is where the file will be loaded to
    mov bx,[arg1]
    mov ah,0x2;int 0x13 read function
    mov dl,[driveindex]
    int 0x13
    .noload mov [returnstatus],byte 0x0
    ret
  .noargs mov si,nofile
    call print
    mov [returnstatus],byte 0x2
    ret
  .gotdir mov bx,dx
    mov [returnstatus],byte 0x3
    inc bx
    mov al,[bx]
    ret

dorun:
  mov [arg1],word 0xa000
  call resolvedir
  cmp byte [returnstatus],0x0
  je .run
  mov si,0x5600
  mov al,[curdir]
  mov [.tmp],al
  mov al,[bindir]
  mov [curdir],al
  call loadfile
  mov al,[.tmp]
  mov [curdir],al
  mov dh, [returnstatus]
  mov [.rtsave],dh
  cmp byte [returnstatus],0x0
  je .run
  ret
  .tmp db 0x0
  .run mov si,0x5600
  .getargs cmp [si],byte 0x0
  je .gotargs
  inc si
  jmp .getargs
  .gotargs inc si
  call 0xa000
  mov [returnstatus],byte 0x0
  mov si,newline
  call print
  ret
  .rtsave db 0x0

chdir:
  mov dx,si
  mov bx,rootstr
  call cmpstrings
  mov si,dx
  cmp byte [returnstatus],0x1
  jne .notroot
  mov [curdir],byte 0x0
  ret
  .notroot mov bx,parentstr
  call cmpstrings
  cmp byte [returnstatus],0x1
  jne .notparent
  call getparentdir
  cmp byte [returnstatus],0x1
  je .noaction
  mov [curdir],ah
  ret
  .notparent mov [arg1],word 0x0000
  call resolvedir
  cmp byte [returnstatus],0x3
  jne .nochdir
  mov [curdir],al
  ret
  .nochdir mov si,nosuchdir
  call print
  .noaction ret

resolvedir:
  mov [.endfull],byte 0x0
  mov dl,[curdir]
  mov [.svdir],dl
  mov dx,si
  cmp [si],byte "/"
  jne .noroot
  mov [curdir],byte 0x0
  inc si
  .noroot mov bx,si
  .loop cmp [si],byte "/"
    je .endofstrwslash
    cmp [si],byte 0x0
    je .endofstrwnull
    inc si
    jmp .loop
    .endofstr mov [si],byte 0x0
      .endofstr2 mov [.sisave],si
      ;mov ah,0xe
      ;mov al,"P"
      ;int 0x10
      mov si,bx
      call loadfile
      cmp [returnstatus],byte 0x3
      jne .end
      mov [curdir],al
      ;mov ah,0xe
      ;add al,0x30
      ;int 0x10
      ;sub al,0x30
      mov si,[.sisave]
      inc si
      mov bx,si
      cmp [.endfull],byte 0x1
      je .end
      jmp .loop
  .svdir db 0x0
  .sisave dw 0x0
  .endfull db 0x0
  .endofstrwnull mov [.endfull],byte 0x1
    jmp .endofstr2
  .endofstrwslash inc si
    cmp [si],byte 0x0
    jne .notend
    mov [.endfull],byte 0x1
    .notend dec si
    jmp .endofstr
  .end mov dl,[.svdir]
  mov [curdir],dl
  ret

getbindir:
  mov si,binstr
  call loadfile
  cmp [returnstatus],byte 0x3
  jne .nobindir
  mov [bindir],al
  ret
  .nobindir mov si,nobindirstr
  call print
  ret

getparentdir:
  mov bx,0x4000;where fs starts
  .loop mov ah,[bx];get entry type
    or ah,ah
    jz .endloop;jump to end if reached end of fs
    cmp ah,0x3
    jne .next;skip check if entry is not a directory
    inc bx;go to entries directory id
    mov ah,[bx];load the dir id
    cmp ah,[curdir];check if it is the current directory
    jne .nextanddec
    add bx,0x2
    mov ah,[bx]
    mov byte [returnstatus],0x0
    ret
    .nextanddec dec bx
    .next add bx,0x10
    jmp .loop
  .endloop mov byte [returnstatus],0x1
  ret

cmpstrings:
    .loop mov al,[si];move char into al and ah to test equality
      mov ah,[bx]
      cmp ah,al
      jne .endloop
      or al,al
      jz .eqstring
      inc si
      inc bx
      jmp .loop
    .endloop mov [returnstatus],byte 0x0
    ret
    .eqstring mov [returnstatus],byte 0x1
    ret

doshow:
  mov [arg1],word 0xa000
  call resolvedir
  cmp byte [returnstatus],0x0
  jne .norun
  mov si,0xa000
  call print
  mov si,newline
  call print
  .norun cmp [returnstatus],byte 0x1
  jne .nospecified
  mov si,nosuchfile
  call print
  .nospecified ret

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

getdiskgeomsg: db "Getting Disk Geometry...",0x0
readfsmsg: db "Reading File System...",0x0
donemsg: db "Done!",0xa,0x0
unknowncmd: db "No such command or file",0xa,0x0
loadedmsg: db "Loaded!",0xa,0x0
newline: db 0xa,0x0
thatsall: db "Placeholder",0xa,0x0
entercommandstring: db ">",0x0
commands: dw lsstring,dols,showstring,doshow,shutdownstring,doshutdown,rebootstring,doreboot,clearstring,clear,cdstring,chdir,0x0
cdstring: db "cd",0x0
lsstring: db "ls",0x0
runstring: db "run",0x0
shutdownstring: db "shutdown",0x0
rebootstring: db "reboot",0x0
clearstring: db "clear",0x0
showstring: db "show",0x0
returnstatus: db 0x0
sectorupto: db 0x0
nofile: db "No file/directory specified",0xa,0x0
nosuchfile: db "No such file",0xa,0x0
nosuchdir: db "No such directory",0xa,0x0
curdir: db 0x0
bindir: db 0x0
binstr: db "bin",0x0
nobindirstr: db "No binaries directory found!",0xa,0x0
arg1: dw 0x0
rootstr: db "/",0x0
parentstr: db "..",0x0
loopdebug: db "loopdebug",0x0
errormsg: db "ERROR!",0x0
floppyboot: db "Booting from Floppy... (No need to get drive parameters)",0xa,0x0

times 2048-($-$$) db 0x0
