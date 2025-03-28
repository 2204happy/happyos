colnum equ 0xb200
ujdrawdir equ 0xb201
ujdrawlb equ 0xb203
ujdrawub equ 0xb205
tmp1 equ 0xb207
tmp2 equ 0xb209
numin equ 0xb20b
numout equ 0xb20d
yscale equ 0xb20f
decing equ 0xb211
opdir equ 0xb212
starcpybytemask equ 0xb213
starbmh equ 0xb214
starbml equ 0xb215
starmirrordrawoffset equ 0xb220
tmp3 equ 0xb222


org 0x0000


mov bx,0xb200
zoloop: cmp bx,0xb222
  jg donezo
  mov [bx],byte 0x0
  inc bx
  jmp zoloop

donezo: mov ah,0x0
mov al,0x13
int 0x10
mov ax,0xa000
mov es,ax
mov ax,0x50
mov fs,ax
call genflag
mov [bufferheight],byte 0xc8
mov [ujdrawlb],word 0x0000
mov [ujdrawub],word 0x7fff
call dispflag
mov ax,0x0
mov es,ax
mov fs,ax
mov ax,0x3
int 0x10
mov ah,0x6
int 0x20


genflag:
  mov si,0x0
  .bgfill cmp si,0x3200
  je .bgfillend
  mov [fs:si],byte 0x1
  inc si
  jmp .bgfill
  .bgfillend mov [colnum],byte 0x0
  mov dx,0x24
  call saltireloop
  mov [ujdrawlb],word 0x0
  
  mov si,ujparams
  mov [tmp3],byte 0x4
  .ujdrawlp call drawlinesr
    dec byte [tmp3]
    jnz .ujdrawlp
  mov bx,stardesc
  mov [tmp3],byte 0x6
  .starcpysrlp call starcpysr
    dec byte [tmp3]
    jnz .starcpysrlp
  ret
  
stardesc:
  db 0x1d,0xb1,0x15,0x0b
  dw cwthstar
  db 0x73,0x89,0x08,0x05
  dw lrgscstar
  db 0x5f,0x1f,0x85,0x19,0x73,0x3e
  db 0x7d,0xa9,0x05,0x03
  dw smlscstar

starcpysr:
  mov al,[bx]
  inc bx
  mov cl,[bx]
  mov si,cwthstar
  inc bx
  mov ch,cl
  and cl,0x7f
  mov dx,bx
  add dx,0x4
  and ch,0x80
  jnz .noretrievebx
  mov bx,[tmp2]
  sub dx,0x4
  .noretrievebx mov [tmp2],bx
  mov [tmp1],dx
  mov dx,[bx]
  mov [starbmh],dx
  add bx,0x2
  mov si,[bx]
  call starcpy
  mov bx,[tmp1]
  ret
  
  
  
drawlinesr:
  mov bx,[si]
  add si,0x2
  mov cx,[si]
  add si,0x2
  mov dx,[si]
  add si,0x2
  mov [tmp2],si
  call drawline
  mov si,[tmp2]
  ret
  
  
  
saltireloop: cmp byte [colnum],0x50
  je .saltireloopend
  cmp byte [colnum],0x28
  jne .notmiddle
  mov ax,[.rsoffsetu]
  mov bx,[.rsoffsetb]
  mov [.rsoffsetu],bx
  mov [.rsoffsetb],ax
  .notmiddle mov si,0x0
  mov ah,0x0
  mov al,[colnum]
  mul byte [bufferheight]
  add si,ax
  mov bl,[colnum]
  and bl,0x1
  cmp bl,0x1
  je .odd
    dec dx
    inc word [.rsoffsetu]
    inc word [.rsoffsetb]
    jmp .slcont
  .odd dec word [.rsoffsetu]
    dec word [.rsoffsetb]
  .slcont mov [ujdrawlb],si
  add si,0x27
  mov [ujdrawub],si
  sub si,dx
  mov [ujdrawdir],word -0x1
  mov ch,0x9
  mov ah,0xf
  call ujdrawpx
  mov [ujdrawdir],word 0x1
  mov si,[ujdrawlb]
  add si,dx
  mov ch,0x9
  mov ah,0xf
  call ujdrawpx
  mov [ujdrawdir],word -0x1
  mov si,[ujdrawub]
  sub si,dx
  sub si,[.rsoffsetu]
  mov ah,0x4
  mov ch,0x3
  call ujdrawpx
  mov [ujdrawdir],word 0x1
  mov si,[ujdrawlb]
  add si,dx
  add si,[.rsoffsetb]
  call ujdrawpx
  inc byte [colnum]
  jmp saltireloop
  .rsoffsetu dw 0x1
  .rsoffsetb dw 0x4
  .saltireloopend ret
  

  
drawline: mov al,[bufferheight];bh=width , bl = starting col, ch=height ,cl = colour, dx=starting row (rotate for screen buffer)
  mul bl 
  add ax,dx
  mov si,ax
  mov ah,cl
  call ujdrawpx
  mov cl,ah
  inc bl
  dec bh
  jnz drawline
  ret
  
ujdrawpx: mov cl,0x0
  .ujdrawpxloop cmp cl,ch
    je .ujdrawpxend
    cmp si,[ujdrawlb]
    jl .ujnd
    cmp si,[ujdrawub]
    jg .ujnd
    mov [fs:si],ah      
    .ujnd add si,[ujdrawdir]
    inc cl
    jmp .ujdrawpxloop
  .ujdrawpxend ret
    


lrgscstar: db 0b00000100,0b01001100,0b01111100,0b00111111,0b11111110
smlscstar: db 0b01000011,0b11111100
ujparams: dw 0x5000,0x0e0f,0x000d,0x0e21,0x280f,0x0000,0x5000,0x0804,0x0010,0x0824,0x2804,0x0000



cwthstar: db 0b00000000,0b00000100,0b00000000,0b00000000,0b01100000,0b00000010,0b00000011,0b00000000,0b00011000,0b00111000,0b00000000,0b01110001,0b11000000,0b00000011,0b11011110,0b00000000,0b00011111,0b11110001,0b11100000,0b01111111,0b11111110,0b00000011,0b11111111,0b11100000,0b01111111,0b11111110,0b00111111,0b11111111,0b11100000

bufferheight: db 0x50


starcpy: mov ch,0x0
  mul byte [bufferheight]
  add ax,cx
  mov bx,ax
  mov al,[starbml]
  mul byte [bufferheight]
  shl ax,0x1
  mov [starmirrordrawoffset],ax
  mov al,[bufferheight]
  mov ah,0x0
  sub [starmirrordrawoffset],ax
  mov dl,0x0
  mov dh,0x0
  mov [starcpybytemask],byte 0b10000000
  .starcpyloop mov al,[si]
  and al,[starcpybytemask]
  jz .nodraw
  mov [fs:bx],byte 0xf
  add bx,[starmirrordrawoffset]
  mov [fs:bx],byte 0xf
  sub bx,[starmirrordrawoffset]
  .nodraw shr byte [starcpybytemask],0x1
    cmp byte [starcpybytemask],0x0
  jne .norollover
    mov [starcpybytemask],byte 0b10000000
    inc si
    jmp .norollover
  .norollover inc bx
  inc dl
  cmp dl,[starbmh]
  jne .starcpyloop
    mov ah,0x0
    mov al,[bufferheight]
    sub [starmirrordrawoffset],ax
    sub [starmirrordrawoffset],ax 
    add bx,ax
    mov al,[starbmh]
    sub bx,ax
    mov dl,0x0
    inc dh
    cmp dh,[starbml]
    jne .starcpyloop
    ret



dispflag:
  mov bx,0x0
  .skyloop mov [es:bx],byte 0x0b
    inc bx
    cmp bx,0xbb80
    jne .skyloop
  .groundloop mov [es:bx],byte 0x02
    inc bx
    cmp bx,0xfa00
    jne .groundloop
  mov bx,0x1f8b
  mov cx,0x0
  .flagpoleloop mov [es:bx],byte 0x07
    inc bx
    inc cx
    cmp cx,0x08
    jne .nffl
      mov cx,0x0
      add bx,0x0138
    .nffl cmp bx,0xdb0b
    jne .flagpoleloop
  mov bx,0x1f93
  mov ax,0
  mov si,0x0
  .flagloop fild word [numin]
    fidiv word [xscale]
    fsin
    fimul word [yscale]
    fistp word [numout]
    inc word [numin]
    mov dx,[numout]
    shl dx,2
    mov ax,0x50
    imul dl
    mov ch,[opdir]
    cmp ch,0x1
    je .notopdir
    add bx,ax
    jmp .nearfli
    .notopdir sub bx,ax
    .nearfli mov ch,0x0
    mov dl,0x0
    .flagloopinner mov cl,[fs:si]
      inc si
      mov [es:bx],cl
      add bx,0x0140
      inc dl
      cmp dl,0x50
      je .nl
      jmp .flagloopinner
    .nl mov bx,0x1f93
    add bx,word [numin]
    cmp bx,0x2033
    jne .flagloop
  mov [numin],word 0x0
  mov ah,0x86
  mov cx,0x8
  mov dx,0x0000
  int 0x15
  mov ax,[yscale]
  
  cmp ax,0x0
    jne .checkmax
    mov byte [decing],0x0
    not byte [opdir]
    and byte [opdir],0x1
  .checkmax cmp ax,0x6
    jne .endcheck
    mov byte [decing],0x1
  .endcheck mov cl,[decing]
  cmp cl,0x0
  jne .gn
  inc byte [yscale]
  jmp .checkkbd
  .gn dec byte [yscale]
  .checkkbd mov ah,0x1
    int 0x16
    jz dispflag
    mov ah,0x0
    int 0x16
    cmp ah,0x1
    jne .checkkbd
    ret
  
  
  xscale: dw 0x10
  dir: dw 0x1

