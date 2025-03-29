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
mov ah,0x8
mov si,exec
mov dx,0x0
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
;ah = 0xb: writeFile
;ah = 0xc: renameFileDir
;ah = 0xd: removeFileDir

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
    call getFileDirEntry
    cmp ah,0x1
    je .noFileFound
    cmp [bx],byte 0x2
    jne .noFileFound
    jmp .fileFound
      
    .noFileFound popa
      mov cl,0xff
      mov dx,0xffff
      pop ds
      iret
      
    .fileFound add bx,0x5
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
    mov bx,di
    call readWriteFile
    popa
    pop ds
    iret

    
  getFileDirName: ;dx = file/dir id, es:di=copy buffer; returns ah = 0x0 on success, al = 0x1 on no file found
    call getFileDirEntry
    cmp ah,0x1
    je .end
    add bx,0x8
    mov si,bx
    call copyStr
    .end mov [.saveah],ah
    popa
    mov ah,[.saveah]
    pop ds
    iret
    .saveah db 0x0
    
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
      cmp [es:si],byte 0x0
      je .done
      inc si
      cmp [es:si],byte 0x0
      je .done
      jmp .rpLoop
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
    .getDirNamesLoop cmp bx,0x0
      je .end
      mov [es:di],byte "/"
      inc di
      pop dx
      mov ah,0x4
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
    
  writeFile: ;dx = file id, es:si = load location
    mov ah,0x3
    mov bx,si
    call readWriteFile
    popa
    pop ds
    iret
    
  renameFileDir: ;dx = file/dir id, es:si = new name, returns ah = 0x0 on success, ah = 0x1 on file not found, ah = 0x2 on name too long/short
    push si
    call strlen
    pop si
    cmp ah,0x17
    jg .tooLongShort
    cmp ah,0x0
    je .tooLongShort
      
    call getFileDirEntry
    
    cmp ah,0x1
    je .fnf
    
    add bx,0x8
    mov di,bx
    call copyStrFromUser
    call saveFs
    mov [.returnStatus],byte 0x0
    
    jmp .end
    
    .tooLongShort mov [.returnStatus],byte 0x2
      jmp .end
    .fnf mov [.returnStatus],byte 0x1
    .end popa
      mov ah,[.returnStatus]
      pop ds
      iret
      
    .returnStatus db 0x0
    
  removeFileDir: ;dx = file/dir id returns ah = 0x0 on success, ah = 0x1 on file not found, ah = 0x2 on dir not empty
    call getFileDirEntry
    cmp ah,0x1
    je .fnf
    cmp [bx],byte 0x3
    jne .canDelete
      push es
      mov ax,cs
      mov es,ax
      mov ah,0x7
      mov di,buffer
      int 0x20
      pop es
      cmp [di],word 0x0
      je .canDelete
      mov [.returnStatus],byte 0x2
      jmp .end
    .canDelete mov [bx],byte 0x4
      call saveFs
      mov [.returnStatus],byte 0x0
      jmp .end
    
    .fnf mov [.returnStatus],byte 0x1
    .end popa
      mov ah,[.returnStatus]
      pop ds
      iret
    
    .returnStatus db 0x0
    
  getFileDirEntry: ;dx = file id, returns bx = pointer to entry, ah=0x0 for success, ah = 0x1 for no file/dir found
    mov bx,0x4000
    .findEntryLoop cmp [bx],byte 0x0
      je .noFile
      mov ah,[bx]
      and ah,0x2
      jz .notFileDirEntry
        inc bx
        cmp [bx],dx
        je .fileFound
        dec bx
      .notFileDirEntry add bx,0x20
      jmp .findEntryLoop
      
    .noFile mov ah,0x1
      ret
      
    .fileFound dec bx
      mov ah,0x0
      ret
    
  readWriteFile: ;dx = file id, es:bx = buffer pointer; ah = 0x2 = read, ah = 0x3 = write
    mov [.rwmode],ah
    
    mov ah,0x2
    int 0x20
    
    mov [.blocks],cl

    mov ax,dx
    mov ch,[sectorsPerTrack]
    shl ch,0x1
    idiv ch
    mov [.track],al
    
    mov al,ah
    mov ah,0x0
    
    mov ch,[sectorsPerTrack]
    idiv ch
    mov [.head],al
    inc ah
    mov [.sector],ah
    
    mov ah,[.rwmode]
    mov ch,[.track]
    mov cl,[.sector]
    mov dh,[.head]
    mov dl,[diskID]
    
    mov al,[.sector]
    dec al
    add al,[.blocks]
    cmp al,[sectorsPerTrack]
    jg .loadInParts
      mov al,[.blocks]
      cmp ah,0x3
      int 0x13
      jmp .end
      
    .loadInParts mov al,[.blocks]
      mov [.blocksLeft],al
      mov al,[sectorsPerTrack]
      sub al,[.sector]
      inc al
      sub [.blocksLeft],al
      push ax
      int 0x13
      pop ax
      push dx
      mul word [.sectorSize]
      pop dx
      add bx,ax
      mov cl,0x1
      .lipLoop cmp [.blocksLeft],byte 0x0
        je .end
        inc dh
        cmp dh,0x2
        jne .notNewTrack
          mov dh,0x0
          inc ch
        .notNewTrack mov al,[.blocksLeft]
          cmp al,[sectorsPerTrack]
          jng .lastSection
            mov al,[sectorsPerTrack]
          .lastSection sub [.blocksLeft],al
          push ax
          mov ah,[.rwmode]
          int 0x13
          pop ax
          push dx
          mul word [.sectorSize]
          pop dx
          add bx,ax
          jmp .lipLoop

    .end ret
    
    .track db 0x0
    .head db 0x0
    .sector db 0x0
    .blocks db 0x0
    .blocksLeft db 0x0
    .sectorSize dw 0x200
    .rwmode db 0x0
  
  saveFs:
    mov si,fspath
    push es
    mov ax,cs
    mov es,ax
    mov ah,0x8
    int 0x20
    mov si,0x4000
    mov ah,0xb
    int 0x20
    pop es
    ret
    
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
    
  copyStrFromUser: cmp [es:si],byte 0x0
    jne .notDone
      mov [di],byte 0x0
      ret
    .notDone mov ch,[es:si]
    mov [di],ch
    inc si
    inc di
    jmp copyStrFromUser
    
  strlen: mov ah,0x0; returns ah = strlen
    .countloop mov al,[es:si]
      cmp al,0x0
      je .done
      inc ah
      inc si
      jmp .countloop
    .done ret
      

  saveSPArray: times 0x10 dw 0x0
  saveSPArrayPtr: db 0x0
  functionArray: dw smile,getFileDirID,getFileSizeLoc,loadFile,getFileDirName,runProgram,returnFromProgram,getDirListing,resolveFullPath,printHexByte,getFullFileDirPath,writeFile,renameFileDir,removeFileDir,0x0
  sectorsPerTrack: db 0x12
  diskID: db 0x0
  curDirStr: db ".",0x0
  parentDirStr: db "..",0x0
  fspath: db "/sys/fs.sys",0x0
  buffer:
  
times 0x600 - ($ - $$) db 0
