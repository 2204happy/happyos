org 0xa000
bits 16

main:
  mov ah,0x8
  mov dl,[0x5fff]
  mov di,0x0
  int 0x13
  mov si,sectorstr
  call [0x6000]
  mov ah,0xe
  mov al,cl
  and al,0x30
  shr al,0x4
  call .printNum
  mov al,cl
  and al,0x0f
  call .printNum
  mov si,trackstr
  call [0x6000]
  shr cx,0x6
  mov al,ch
  and al,0x3
  call .printNum
  mov al,cl
  and al,0xf0
  shr al,0x4
  call .printNum
  mov al,cl
  and al,0x0f
  call .printNum
  mov dl,[0x5fff]
  mov ah,0x00
  int 0x13
  ret
  
  .printNum add al,0x30
    cmp al,0x3a
    jl .noadd
    add al,0x7
    .noadd int 0x10
    ret
    

sectorstr: db "Sectors Per Track: 0x",0x0
trackstr: db 0xa,0xd,"Last Cylinder Index: 0x"
