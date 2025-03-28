realIncrement equ 0xb000
imaginaryIncrement equ 0xb008
cr equ 0xb010
ci equ 0xb018
zr equ 0xb020
zi equ 0xb028
working equ 0xb030
x87status equ 0xb040
centreR equ 0xb050
centreI equ 0xb058
realsWidth equ 0xb060
imaginaryHeight equ 0xb068
zList equ 0xb080


org 0x0000




mov si,welcomeMsg
call print
mov ah,0x0
int 0x16

mov bx,0xb000
zoloop: cmp bx,0xffff
  jg donezo
  mov [bx],byte 0x0
  inc bx
  jmp zoloop

donezo: mov ax,0x11
int 0x10
 
mov ax,0xa000
mov es,ax



fld1
fidiv word [two]
fimul word [negativeone]
fst qword [centreR]
fldz
fstp qword [centreI]
fild word [realsWidthInit]
fstp qword [realsWidth]
fild word [imaginaryHeightInit]
fstp qword [imaginaryHeight]

mainLoop: call drawSet
  call getInput
  cmp ah,0x1
  je quit
  call zeroOutScreen
  jmp mainLoop
  
quit:
  mov ax,0x0
  mov es,ax
  mov ax,0x3
  int 0x10
  mov ah,0x6
  int 0x20

drawSet:
  fld qword [realsWidth]
  fidiv word [screenWidth]
  fstp qword [realIncrement]
  fld qword [imaginaryHeight]
  fidiv word [screenHeight]
  fstp qword [imaginaryIncrement]
  mov ax,0x0
  mov bx,0x0
  fld qword [imaginaryHeight]
  fidiv word [two]
  fadd qword [centreI]
  fstp qword [ci]
  .lpouter cmp ax,0x1e0
    je .lpouterend
    mov bx,0x0
    fld qword [realsWidth]
    fidiv word [two]
    fimul word [negativeone]
    fadd qword [centreR]
    fstp qword [cr]
    .lpinner cmp bx,0x280
      je .lpinnerend
      call flipByCoord
      fld qword [cr]
      fadd qword [realIncrement]
      fstp qword [cr]
      call checkNumberInMandelbrot
      cmp dx,0x0
      je .noflip
        call flipByCoord
      .noflip add bx,0x1
      jmp .lpinner
    .lpinnerend fld qword [ci]
    fsub qword [imaginaryIncrement]
    fstp qword [ci]
    add ax,0x1
    jmp .lpouter
  .lpouterend ret

zeroOutScreen:
  mov si,0x0
  .lp cmp si,0x9600
    je .endlp
    mov [es:si],byte 0x0
    inc si
    jmp .lp
  .endlp ret


flipByCoord: pusha
  mul word [screenByteWidth]
  mov cl,bl
  and cl,0x7
  shr bx,0x3
  add ax,bx
  mov dl,0x1
  shl dl,0x7
  shr dl,cl
  mov si,ax
  xor [es:si],dl
  popa
  ret

  
checkNumberInMandelbrot: pusha ;ax = c,returns dx boolean is in the set
  mov ax,cr
  mov bx,word [iterAmnt]
  mov si,zList
  fldz
  fst qword [si]
  add si,0x8
  fstp qword [si]
  sub si,0x8
  .iterLoop cmp bx,0x0
    je .endIterLoop
    mov cx,si
    add cx,0x10
    call mandelbrotEquCalc
    add si,0x10
    call mandelbrotCheckConvergence
    cmp dx,0x1
    jne .notFoundConv
      mov bx,cx
      fld qword [bx]
      fistp word [working]
      cmp [working],word -0x1
      jl .nz
      cmp [working],word 0x0
      jg .nz
      jmp .endIterLoop
      .nz popa
      mov dx,0x1
      ret
    .notFoundConv dec bx
    jmp .iterLoop
  .endIterLoop popa
  mov dx,0x0
  ret
  .tmp dw 0x0
  
  
mandelbrotCheckConvergence: pusha;si=upto; returns dx=1 on convergence
  mov bx,zList
  .lp cmp bx,si
    je .endlp
    call compareFloat
    cmp dx,0x0
    je .convNotFound
      add si,0x8
      add bx,0x8
      call compareFloat
      cmp dx,0x0
      je .convNotFoundRE
        popa
        mov dx,0x1
        ret
    .convNotFoundRE sub bx,0x8
    sub si,0x8
    .convNotFound add bx,0x10
    jmp .lp
  .endlp popa
  mov dx,0x0
  ret

compareFloat: 
  fld qword [si]
  fcomp qword [bx]
  fnstsw [x87status]
  and word [x87status],0b0100000000000000
  cmp word [x87status],0x0
  je .isne
    mov dx,0x1
    ret
  .isne mov dx,0x0
    ret
  
mandelbrotEquCalc: pusha;si = z, ax = c,cx=dest
  mov dx,cx
  mov bx,working
  call complexSquare
  mov cx,working
  mov bx,dx
  call complexAdd
  popa
  ret

  
  
complexSquare: pusha;si=source,bx=destination
  call .square
  add si,0x8
  add bx,0x8
  call .square
  sub bx,0x8
  fld qword [bx]
  add bx,0x8
  fsub qword [bx]
  sub bx,0x8
  fstp qword [bx]
  fld qword [si]
  sub si,0x8
  fmul qword [si]
  fimul word [two]
  add bx,0x8
  fstp qword [bx]
  popa
  ret
  .square fld qword [si]
    fmul qword [si]
    fstp qword [bx]
    ret




complexAdd: pusha;ax=add1,cx=add2,bx=dest
  call .radd
  add ax,0x8
  add cx,0x8
  add bx,0x8
  call .radd
  popa
  ret
  .radd mov si,ax
    fld qword [si]
    mov si,cx
    fadd qword [si]
    fstp qword [bx]
    ret
    

print: mov ah,0xe
  .lp cmp [si],byte 0x0
    je .endlp
    mov al,[si]
    int 0x10
    inc si
    jmp .lp
  .endlp ret
  
zoom: fld qword [realsWidth]
  call .componentZoom
  fstp qword [realsWidth]
  fld qword [imaginaryHeight]
  call .componentZoom
  fstp qword [imaginaryHeight]
  ret
  .componentZoom cmp al,0x1
    je .dezoom
    fimul word [two]
    fidiv word [three]
    ret
    .dezoom fidiv word [two]
    fimul word [three]    
    ret
    
moveCentre:
  cmp al,0x2
  jl .lr
    mov si,imaginaryHeight
    mov bx,centreI
    jmp .ud
  .lr mov si,realsWidth
    mov bx,centreR
  .ud fld qword [si]
  fidiv word [four]
  and al,0x1
  jnz .right
    fsubr qword [bx]
    jmp .left
  .right fadd qword [bx]
  .left fstp qword [bx]
  ret
  
getInput:
  mov ah,0x0
  int 0x16
  mov bl,ah
  cmp ah,0x1
  jne .ne
    mov ah,0x1
    ret
  .ne cmp bl,0x13
  jl .nds
    sub bl,0xb
  .nds sub bl,0x10
  mov bh,0x0
  cmp bx,0x5
  ja getInput
  shl bx,0x1
  add bx,keyBindings
  call [bx]
  mov ah,0x0
  ret
  
  
qPress: add [iterAmnt],word 0x3
  mov al,0x0
  call zoom
  ret

ePress: sub [iterAmnt],word 0x3
  mov al,0x1
  call zoom
  ret
  
wPress: mov al,0x3
  call moveCentre
  ret

sPress: mov al,0x2
  call moveCentre
  ret

aPress: mov al,0x0
  call moveCentre
  ret
  
dPress: mov al,0x1
  call moveCentre
  ret
  
  

iterAmnt: dw 0x1d
keyBindings: dw qPress,wPress,ePress,aPress,sPress,dPress
screenByteWidth: dw 0x50
screenWidth: dw 0x280
screenHeight: dw 0x1e0
realsWidthInit: dw 0x3
imaginaryHeightInit: dw 0x2
two: dw 2
four: dw 4
three: dw 3
negativeone: dw -1
welcomeMsg: db "MandelBOOT!",0x1,0x2,0xa,0xd,0xa,"**************************",0xa,0xd,"Mandelbrot Fractal in <1KB",0xa,0xd,"**************************",0xa,0xd,0xa,"Controls",0x3a,0xa,0xd,"WASD = Move",0xa,0xd,"Q = Zoom in",0xa,0xd,"E = Zoom Out",0xa,0xd,0xa,"Press any key to continue...",0x0
