bits 16

call getNextString
cmp [es:si],byte 0x0
je notEnoughArguments

push dx
mov ah,0x8
int 0x20
pop dx

cmp cl,0x2
je .nofile
  mov si,alreadyExists
  call print
  jmp end
  
.nofile call getNextString
sub si,0x2
.mkfileLoop cmp [es:si],byte "/"
    je .inOtherDir
    cmp [es:si],byte 0x0
    je .inThisDir
    dec si
    jmp .mkfileLoop

.inOtherDir mov [es:si],byte 0x0
    dec si
    cmp [es:si],byte 0x0
    jne .notFromRoot
    mov dx,0x0
    add si,0x2
    jmp .doMkfile
    .notFromRoot call getPrevString
    mov ah,0x8
    int 0x20
    cmp cl,0x1
    je .doMkfileOD
    push si
    mov si,mkfileStr
    call print
    pop si
    mov di,buffer
    call copyStr
    mov si,buffer
    call print
    cmp cl,0x0
    je .isFile
        mov si,nosuchdir
        call print
        jmp end
    .isFile mov si,notADir
        call print
        jmp end

.inThisDir inc si
    jmp .doMkfile
.doMkfileOD call getNextString
.doMkfile mov di,si
    mov ah,0xe
    mov al,0x2
    int 0x20
    cmp ah,0x0
    je .success
      mov si,mkfileError
      call print
    .success jmp end
  
  
notEnoughArguments:
  mov si,notEnoughArgumentsStr
  call print

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
  

getNextString: cmp [es:si],byte 0x0
  je .end
  inc si
  jmp getNextString
  .end inc si
  ret
  
getPrevString: cmp [es:si],byte 0x0
  je .end
  dec si
  jmp getPrevString
  .end inc si
  ret
  
copyStr: 
  cmp [es:si],byte 0x0
  je .end
  mov ax,[es:si]
  mov [di],ax
  inc si
  inc di
  jmp copyStr
  .end ret

notEnoughArgumentsStr: db "Usage: mkfile [name of file] [Number of 512B blocks]",0xa,0xd,0x0

alreadyExists: db "mkfile: File/directory already exists",0xa,0xd,0x0
notADir: db " is not a directory",0xa,0xd,0x0
mkfileError: db "mkfile: Could not make file",0xa,0xd,0x0
mkfileStr: db "mkfile: ",0x0
nosuchdir: db "No such directory",0xa,0xd,0x0
buffer:
