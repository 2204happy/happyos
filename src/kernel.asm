bits 16


mov [diskID],dl
mov bx,0x80
mov [bx],word int20
add bx,0x2
mov [bx],word 0x7000

mov ax,cs
mov ds,ax

mov ah,0x0
int 0x20

mov ax,0x7000
mov es,ax
mov ah,0x1
mov si,exec
mov dx,0x0
int 0x20
inc si
mov ah,0x1
int 0x20
mov ax,0x5000
mov es,ax
mov di,0x0
mov ah,0x3
int 0x20

jmp 0x5000:0x0000


exec: db "sys/shell.sys",0x0

  
int20:
;ah = 0x0: smile
;ah = 0x1: getFileDirID
;ah = 0x2: getFileSizeLoc
;ah = 0x3: loadFile
;ah = 0x4: getFileDirName
;ah = 0x5: runProgram
;ah = 0x6: returnFromProgram
;ah = 0x7: getDirListing
;ah = 0x8: resolveFullPath
;ah = 0x9: printHexByte
;ah = 0xa: getFullFileDirPath

  push ds
  pusha
  push cx
  push ax
  mov ax,cs
  mov ds,ax
  pop ax
  mov bx,functionArray
  shl ah,0x1
  mov cl,ah
  mov ch,0x0
  add bx,cx
  pop cx
  jmp [bx]
  
  smile:
    mov ah,0xe
    mov al,":"
    int 0x10
    mov al,")"
    int 0x10
    popa
    pop ds
    iret
  
  getFileDirID: ;es:si = pointer to dir name, dx = parent directory id, returns dx = file/directory id, cl=0x0 for files, 0x1 for directories,0x2 for no file/directory found
    ;check if dir name is ".." or "."
    mov [.lookingForParentDir],byte 0x0
    mov cx,si
    mov bx,curDirStr
    call cmpStr
    cmp ah,0x1
    jne .notCurDir
      mov cl,0x1
      jmp .curDirFound
    .notCurDir mov si,cx
    mov bx,parentDirStr
    call cmpStr
    mov bx,0x4000
    cmp ah,0x1
    jne .noDots
    mov [.lookingForParentDir],byte 0x1
    .noDots mov si,cx
    .checkEntryLoop mov ah,[bx]
      cmp ah,0x0
      je .noFileDirFound
      and ah,0x2
      cmp ah,0x2
      jne .wrongEntryType
      cmp [.lookingForParentDir],byte 0x0
      je .notLFPD
        mov ah,[bx]
        cmp ah,0x3
        jne .wrongEntryType
        inc bx
        cmp [bx],dx
        jne .wrongParentDirectory
          mov cl,0x1
          add bx,0x2
          jmp .parDirFound
      .notLFPD add bx,0x3
        cmp [bx],dx
        jne .wrongParentDirectory
        add bx,0x5
        call cmpStr
        cmp ah,0x1
        je .fileDirFound
        mov si,cx
      .wrongParentDirectory and bx,0xffe0
      .wrongEntryType add bx,0x20
      jmp .checkEntryLoop
    
    .lookingForParentDir db 0x0
      
    .noFileDirFound popa
      mov cl,0x2
      pop ds
      iret
      
    .fileDirFound and bx,0xffe0
      mov cl,[bx]
      and cl,0x1
      inc bx
      .parDirFound mov dx,[bx]
      .curDirFound mov [.savecl],cl
      mov [.savedx],dx
      mov [.savesi],si
      popa
      mov dx,[.savedx]
      mov si,[.savesi]
      mov cl,[.savecl]
      pop ds
      iret
      .savedx dw 0x0
      .savesi dw 0x0
      .savecl db 0x0
      
      
  getFileSizeLoc: ;dx = file id, returns cl = size, dx = location
    mov bx,0x4000
    .checkEntryLoop mov ah,[bx]
      cmp ah,0x0
      je .noFileFound
      cmp ah,0x2
      jne .notFileEntry
      inc bx
      cmp [bx],dx
      je .fileFound
      dec bx
      .notFileEntry add bx,0x20
      jmp .checkEntryLoop
      
    .noFileFound popa
      mov cl,0xff
      mov dx,0xffff
      pop ds
      iret
      
    .fileFound add bx,0x4
      mov dx,[bx]
      add bx,0x2
      mov cl,[bx]
      mov [.savedx],dx
      mov [.savecl],cl
      popa
      mov dx,[.savedx]
      mov cl,[.savecl]
      pop ds
      iret
      .savedx dw 0x0
      .savecl db 0x0
  
  loadFile: ;dx = file id, es:di = load location
    mov ah,0x2
    int 0x20
    mov bx,di
    mov ax,dx
    mov ch,[sectorsPerTrack]
    shl ch,0x1
    idiv ch
    mov [.track],al
    
    mov al,ah
    mov ah,0x0
    
    mov ch,[cs:sectorsPerTrack]
    idiv ch
    mov [.head],al
    inc ah
    mov [.sector],ah
    
    mov ax,0x46
    push ax
    popf
    mov ah,0x2
    mov al,cl
    mov ch,[.track]
    mov cl,[.sector]
    mov dh,[.head]
    mov dl,[diskID]
    int 0x13
    popa
    pop ds
    iret
    
    .track db 0x0
    .head db 0x0
    .sector db 0x0
    
  getFileDirName: ;dx = file/dir id, es:di=copy buffer;
    mov si,0x4000
    .findFileDirEntry mov ah,[si]
      cmp ah,0x0
      je .end
      and ah,0x2
      cmp ah,0x2
      jne .notFileDirEntry
        inc si
        cmp [si],dx
        jne .wrongFileDirEntry
          add si,0x7
          call copyStr
          jmp .end
      .wrongFileDirEntry dec si
      .notFileDirEntry add si,0x20
      jmp .findFileDirEntry
    
    .end popa
    pop ds
    iret
    
  runProgram: ;es:si = command line, cx=code segment for program; dx=working directory
    mov [address+2],cx
    mov bx,saveSPArray
    add bx,[saveSPArrayPtr]
    mov ax,sp
    mov [bx],ax
    inc byte [saveSPArrayPtr]
    mov ds,cx
    jmp far [cs:address]
    address: dw 0x0,0x0
    
    
  returnFromProgram:
    popa
    pop ax
    dec byte [saveSPArrayPtr]
    mov bx,saveSPArray
    add bx,[saveSPArrayPtr]
    mov ax,[bx]
    mov sp,ax
    popa
    pop ds
    iret
    
  getDirListing: ;es:di=id buffer, dx=directory id
    mov bx,0x4000
    .checkEntryLoop mov ah,[bx]
      cmp ah,0x0
      je .done
      and ah,0x2
      jz .notFileDirEntry
        add bx,0x3
        cmp [bx],dx
        jne .wrongParentDir
        sub bx,0x2
        mov ax,[bx]
        mov [es:di],ax
        add di,0x2
      .wrongParentDir and bx,0xffe0
      .notFileDirEntry add bx,0x20
      jmp .checkEntryLoop
    .done mov [es:di],word 0x0
    popa
    pop ds
    iret
    
  resolveFullPath: ;es:si = path string, dx = working directory, returns getFileID equivalent
    cmp [es:si],byte "/"
    jne .rpLoop
      mov dx,0x0
      inc si
      cmp [es:si],byte 0x0
      jne .rpLoop
        mov cl,0x1
        jmp .done
    .rpLoop mov ah,0x1
      int 0x20
      cmp cl,0x1
      jne .done
      inc si
      cmp [es:si],byte 0x0
      jne .rpLoop
    .done mov [.savedx],dx
    mov [.savecl],cl
    popa
    mov dx,[.savedx]
    mov cl,[.savecl]
    pop ds
    iret
    
    .savedx dw 0x0
    .savecl db 0x0
  
  printHexByte: ;al = byte to print
    mov ah,0xe
    push ax
    shr al,0x4
    call .printHexNibble
    pop ax
    and al,0x0f
    call .printHexNibble
    mov al," "
    int 0x10
    popa
    pop ds
    iret
    
    .printHexNibble add al,0x30
      cmp al,0x3a
      jl .notLetter
        add al,0x7
      .notLetter int 0x10
      ret
      
  getFullFileDirPath: ;es:di = write buffer, dx = directory/file id
    cmp dx,0x0
    jne .notRoot
      mov [es:di],byte "/"
      inc di
      mov [es:di],byte 0x0
      jmp .end
    .notRoot mov ax,es
    mov [.savees],ax
    mov ax,ds
    mov es,ax
    mov bx,0x0
    .getDirParentsLoop:
      push dx
      inc bx
      mov ah,0x1
      mov si,parentDirStr
      int 0x20
      cmp dx,0x0
      je .gdplEnd
      jmp .getDirParentsLoop
    .gdplEnd mov ax,[.savees]
    mov es,ax
    mov ah,0x4
    .getDirNamesLoop cmp bx,0x0
      je .end
      mov [es:di],byte "/"
      inc di
      pop dx
      int 0x20
      .eosLoop cmp [es:di],byte 0x0
        je .elEnd
        inc di
        jmp .eosLoop
      .elEnd dec bx
      jmp .getDirNamesLoop
    .end popa
    pop ds
    iret
    .savees dw 0x0
    
  printTest: pusha
    mov ah,0xe
    mov al,":"
    int 0x10
    popa
    ret
     
  printTest2: pusha
    mov ah,0xe
    mov al,"|"
    int 0x10
    popa
    ret
     
  cmpStr: mov ah,[es:si]
    cmp ah,"/"
    jne .noslash
    mov ah,0x0
    .noslash or ah,[bx]
    jz .stringMatch
    mov ah,[es:si]
    cmp ah,[bx]
    jne .noMatch
    inc bx
    inc si
    jmp cmpStr
    
    .stringMatch mov ah,0x1
      ret
      
    .noMatch mov ah,0x0
      ret
  
  copyStr: cmp [si],byte 0x0
    jne .notDone
      mov [es:di],byte 0x0
      ret
    .notDone mov ch,[si]
    mov [es:di],ch
    inc si
    inc di
    jmp copyStr
      

  saveSPArray: times 0x10 dw 0x0
  saveSPArrayPtr: db 0x0
  functionArray: dw smile,getFileDirID,getFileSizeLoc,loadFile,getFileDirName,runProgram,returnFromProgram,getDirListing,resolveFullPath,printHexByte,getFullFileDirPath,0x0
  sectorsPerTrack: db 0x12
  diskID: db 0x0
  curDirStr: db ".",0x0
  parentDirStr: db "..",0x0
  
times 1024 - ($ - $$) db 0
