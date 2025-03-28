bits 16
org 0x0000


jmp main;jump to mainloop
quit:;called when player presses escape
  mov si,quitconfirm
  call printstr;ask for quit confirmation
  .loop mov ah,0x0
    int 0x16;wait for input
    cmp al,"y"
    je reallyquit;if input = "y" then quit the program
    cmp al,"n"
    je waitforinputnodesc;if input = "n" jump back to the main part of the program
    jmp .loop;otherwise jump back to start of loop and wait for input
  reallyquit: mov ah,0x6
  int 0x20;quit the program

setquittingByte: mov byte [quitting],0x1;quit game
  ret

main:
  jmp waitforinput;jump main input loop
  getcurroom:
    mov ax,[curroom];move current room index into ax
    mov bx,rooms;move room (array of 6 byte elements) memory address into bx
    
    ;multiply by 6 (elements are 6 bytes as they contain 3 16-bit memory addresses)
    add ax,ax
    mov cx,ax
    add ax,ax
    add ax,cx

    add bx,ax;move to offset in room array
    ret
  waitforinput:
    call getcurroom;get current room element in room array
    add bx,0x2;move to description
    mov bx,[bx]
    mov si,bx;move memory address of begining of description string in to the source index register
    call printstr;print room description
    waitforinputnodesc: cmp [quitting],byte 0x1
    je reallyquit
    mov si,reqaction
    call printstr;print string asking for player input
    .waitforvalidinputloop mov ah,0x0
      int 0x16;wait for input
      cmp al,"m"
      je move;if "m" key is pressed jump to the move function
      cmp al,"i"
      je showinventory;if "i" key is pressed jump to showinventory function
      cmp al,"l"
      je interact;if "l" key is pressed jump to interact/look around function
      cmp al,0x1b
      je quit;if escape key is pressed jump to quit function
    jmp .waitforvalidinputloop;otherwise jump back to start of input loop and wait for another input
  move:
    call getcurroom;get current room element
    mov bx,[bx];load memory address of current rooms directions
    mov dl,0x31;move value of "1" into dl register (what button to press)
    showdirloop:;loop to print out or possible directions
      mov ax,[bx]
      or ax,ax
      jz endshowdirloop;jump to the end of the loop if the end of the directions array has been reached
      cmp ax,0xffff
      je .skip;0xffff means a null value but not the end of the list (so directions can be enabled/disabled after certain events)
      mov [tmp0],dl;save dl value into memory as it will be overwritten, but original value is still going to be needed
      mov ah,0xe
      mov al,dl
      int 0x10;print out the key to press to go to that room
      mov al,")"
      int 0x10;print parenthesis (entries look like this "1)left")
      add bx,0x2;move to where the move direction description (eg. "left" or "right") is located
      mov si,[bx]
      call printstr;print move direction description
      add bx,0x2;move to next element in array
      mov dl,[tmp0];load back original dl value
      inc dl;increment dl value
      jmp showdirloop;jump to start of loop
      .skip inc dl;this segment is run when a value of 0xffff is found for the room id, just increments dl and moves bx to next element
      add bx,0x4
      jmp showdirloop
    endshowdirloop:
    mov [tmp0],dl;save dl value (print function overrides dl)
    mov si,pressescmsg
    call printstr;print message notifying player of option to cancel move by pressing escape
    mov dl,[tmp0];load back dl value
    .waitforvalidinput mov ah,0x0
      int 0x16;wait for input
      cmp al,0x1b
      je waitforinputnodesc;leave the move function if escape is pressed
      cmp al,0x31
      jb .waitforvalidinput;wait for a valid input if ascii value is less than "1" (0x31)
      cmp al,dl
      jae .waitforvalidinput;what for a valid input if ascii value is above the max allowed input
      sub al,0x31;subtract 0x31 from hex value so "1" becomes 0x1, "2" becomes 0x2 etc
      mov [tmp0],al;save al value
      call getcurroom
      mov bx,[bx];load directions array pointer into bx
      mov al,[tmp0];load al value
      mov ah,0x0;set ah to zero, therefore making ax = al (ah and al are just low and high bytes of ax register) essentially making the 8-bit integer a 16-bit one
      ;multipy ax by 4 (elements are 4 bytes)
      add ax,ax
      add ax,ax
      add bx,ax;add ax offset to directions array pointer
      mov bx,[bx]
      cmp bx,0xffff
      je .waitforvalidinput;;if room id = 0xffff, jump back to wait for another input
      sub bx,0x1000;subtract 0x1000 from room id, room id's are stored that way to differentiate between 0x0 (end of array)
      mov [curroom],bx;load new room id into memory location holding curent room
      mov si,newline
      call printstr;print a linebreak
    .validinputloopend jmp waitforinput;jump back to asking the player for an action
  showinventory:
    mov si,inventorystr
    call printstr;print message notifying player that inventory contents are being displayed
    mov bx,inventory;move bx to inventory array
    .invloop mov [tmp0],bx;save value of bx
      mov bx,[bx];load id of current inventory item being checked
      or bx,bx
      jz .endinvloop;jump to end of loop if end of inventory is reached (id 0x0)
      cmp bx,0xffff
      je .skip;skip print for this item as it is null but not end of list (id 0xffff)
      sub bx,0x1000;otherwise subtract 0x1000 from id (stored with an added value of 0x1000 do differentiate from end of array)
      mov ax,bx
      add ax,ax;multiply id by two (elements in items list are 2 bytes)
      mov bx,itemslist;load items array
      add bx,ax;move to item offset
      mov si,[bx];elements in array are pointers to strings of the names of the item
      call printstr;print item
      mov si,newline
      call printstr;print newline
      .skip mov bx,[tmp0];load original bx value back
      add bx,0x2;increment bx by 2
      jmp .invloop;jump back to start of loop
    .endinvloop jmp waitforinputnodesc;jump back to asking the player for an action
  interact:;interact instructions are as follows: 0x1 = print message, 0x2 = item, 0x3 = script
    mov si,newline
    call printstr;print new line
    call getcurroom;get current room element
    add bx,0x4
    mov bx,[bx];load the memory address of the interact/look around instructions for the given room
    .loop mov ax,[bx];load in current interact instruction
      mov [tmp0],bx;save bx value
      cmp ax,0x0
      je .endloop;jump to end of loop if end of array is found
      cmp ax,0xffff
      je .nearendloop;skip processing for current instruction if instruction = 0xffff (null but not end of array)
      ;these cmps and jnes act as ifs and else ifs
      cmp ax,0x1;if instruction = 0x1, print message
      jne .notprint
        mov si,bx
        add si,0x2
        mov si,[si]
        call printstr;load and print message
        jmp .nearendloop
      .notprint cmp ax,0x2;else if instruction = 0x2,request an item pickup
      jne .noitem
        mov si,pickupmsg0
        call printstr;print first part of pickup message
        ;load item requested to be picked up into cx
        add bx,0x2
        mov cx,[bx]
        ;print item name
        mov ax,cx
        sub ax,0x1000
        add ax,ax
        mov si,itemslist
        add si,ax
        mov si,[si]
        call printstr
        mov si,newline
        call printstr;print newline
        mov si,pickupmsg1
        call printstr;print second part of pickup message
        .inputloop mov ah,0x0
          int 0x16;wait for input
          cmp al,"y"
          je .pickup;if player enters "y", do pickup logic
          cmp al,"n"
          je .nopickup;if player enters "n",skip pickup logic
          jmp .inputloop;otherwise wait for valid input
        .pickup call addtoinv;call add to inventory function (takes cx as item id)
        mov bx,[tmp0];recall initial bx value
        mov [bx],word 0xffff;overwrite pickup instruction with 0xffff so it can't be picked up twices
        .nopickup jmp .nearendloop
      .noitem cmp ax,0x3;else if instruction = 0x3 run a "custom script/routine"
      jne .nearendloop
        add bx,0x2
        mov bx,[bx]
        call bx;run "script"
      .nearendloop mov bx,[tmp0];reload original bx value
      add bx,0x4;increment bx to next element
      jmp .loop;return to start of loop
    .endloop mov si,newline
    call printstr;print newline
    jmp waitforinputnodesc;jump back to asking player for an action

addtoinv:
  mov bx,inventory;move inventory array into bx
  .loop cmp [bx],word 0x0;if current element in inventory array = 0x0 or 0xffff, store the new item here
    je .foundslot
    cmp [bx],word 0xffff
    jne .iterateloop;otherwise check next element
    .foundslot mov [bx],cx;save id of new item
      mov si,obtainmsg
      call printstr;print message to notify player obtained item
      ;print name of item
      sub cx,0x1000
      add cx,cx
      mov bx,itemslist
      add bx,cx
      mov si,[bx]
      call printstr
      mov si,newline
      call printstr;print newline
      ret;return to whatever function called this one
    .iterateloop add bx,0x2;increment bx to next element
    jmp .loop

checkifhascottagekeys:
  mov bx,inventory
  .loop mov ax,[bx]
    or ax,ax
    jz .nokeys;if end of array has been reached and no cottage keys have been found, quit the function
    cmp ax,0x1000
    je .haskeys;if item with id of 0x1000 is found (cottage keys), modify certain room properties
    add bx,0x2
    jmp .loop
  .nokeys ret;quit the function
  .firstrun db 0x1
  .haskeys cmp [.firstrun],byte 0x0
  je .quit;only run once
  mov [.firstrun],byte 0x0;set flag that code has already been run
  mov bx,cottageinteract
  add bx,0x2
  mov [bx],word nothingofinterest;change interact message to show "nothing of interest"
  mov si,cottagedooropen
  call printstr
  ;enable entrance to house
  mov bx,cottagedirections
  add bx,0x8
  mov [bx],word 0x1004;foyer room id
  mov bx,rooms
  add bx,0x8
  mov [bx],word cottagedescunlocked;change cottage room description
  .quit ret

checkifhascarkeys:;this function is similar to the function above, in hindsight they could've been merged
  mov bx,inventory
  .loop mov ax,[bx]
    or ax,ax
    jz .nokeys
    cmp ax,0x1001
    je .haskeys
    add bx,0x2
    jmp .loop
  .nokeys ret
  .firstrun db 0x1
  .garagerun db 0x1
  .haskeys cmp [curroom],word 0x2
  je .atgarage;this function is also run when interact action happens at garrage, but different things are changed
  cmp [.firstrun],byte 0x0
  je .quit
  mov [.firstrun],byte 0x0
  mov bx,kitcheninteract
  add bx,0x2
  mov [bx],word nothingofinterest;change interact description of kitchen
  mov bx,rooms
  add bx,0xe
  mov [bx],word garagedescunlocked
  jmp .quit
  .atgarage cmp [.garagerun],byte 0x0
  je .quit
  mov [.garagerun],byte 0x0
  mov si,garagedooropen
  call printstr;notify garrage door being opened
  mov bx,garagedirections
  add bx,0x8
  mov [bx],word 0x1008;add direction into car
  mov bx,garageinteract
  mov [bx],word 0x1
  add bx,0x2
  mov [bx],word alreadyopenedgarage;change interact description of car
  add bx,0x2
  mov [bx],word 0x0
  mov bx,rooms
  add bx,0xe
  mov [bx],word garagedescopen;change garrage description
  .quit ret

checkifhaspistol:;this function is also very similar
  mov bx,inventory
  .loop mov ax,[bx]
    or ax,ax
    jz .nopistol
    cmp ax,0x1002
    je .haspistol
    add bx,0x2
    jmp .loop
  .nopistol ret
  .firstrun db 0x1
  .haspistol cmp [.firstrun],byte 0x0
  je .quit
  mov [.firstrun],byte 0x0
  mov bx,bedroominteract
  add bx,0x2
  mov [bx],word nothingofinterest;change interact description of bedroom
  .quit ret

turnoncar:;car keys aren't needed to be checked as car can only be accessed after keys have been aquired
  mov si,cargarageinteractmsg
  call printstr
  mov bx,cargarageinteract
  mov [bx],word 0x1
  add bx,0x2
  mov [bx],word cargarageinteractmsgafterignition;change car interact message
  mov bx,cargaragedirections
  add bx,0x4
  mov [bx],word 0x1009;add drive out to street direction
  ret

chasmexplore:
  mov si,chasmobservestr
  call printstr;ask if player wants to move closer
  .loop mov ah,0x0
    int 0x16
    cmp al,"y"
    je .yes
    cmp al,"n"
    je .no
    jmp .loop
  .no mov si,chasmretreat;cancel ending
    call printstr
    ret
  .yes mov si,chasmdeath;kill player
    call printstr
    mov si,gameover
    call printstr
    mov byte [quitting],0x1;quit game
    ret

zombiescene:
    ;check to see if player has pistol
    mov bx,inventory
  .loop mov ax,[bx]
    or ax,ax
    jz .nopistol
    cmp ax,0x1002
    je .haspistol
    add bx,0x2
    jmp .loop
    .nopistol mov si,zombiedeath;if player has no pistol kill player
      call printstr
      mov si,gameover
      call printstr
      mov byte [quitting],0x1;quit game
      ret
    .haspistol mov si,zombiesurvive 
      call printstr
      mov bx,outskirtsdirections
      add bx,0x4
      mov [bx],word 0x100c;add direction to city center
      mov bx,rooms
      add bx,0x44
      mov [bx],word outskirtsdescnozombies;change outskirt description
      mov bx,outskirtsinteract
      mov [bx],word 0x1
      add bx,0x2
      mov [bx],word nothingofinterest;change outskirt interact description
      ret

redbutton:
  mov si,pressbuttonmsg;ask player to press red button
  call printstr
  .loop mov ah,0x0
    int 0x16
    cmp al,"y"
    je .press
    cmp al,"n"
    je .nopress
    jmp .loop
  .nopress mov si,nopush;if player says no, cancel ending
    call printstr
    ret
  .press mov si,wakeup;otherwise give player the 'good' ending
    call printstr
    mov si,gameover
    call printstr
    mov byte [quitting],0x1;quit game
    ret

printstr:
  mov ah,0xe;tells int 10h to print character
  .printloop mov al,[si];move value at si into dl
    or al,al
    jz .endprintloop;if al = 0x0, end of string is reached, return to program
    int 0x10;print character to screen
    inc si;increment si to next character
    jmp .printloop;jump to start of loop
  .endprintloop ret



quitting: db 0x0
pressescmsg: db "Press Esc to Cancel",0xa,0xd,0x0
zombiedeath: db "In order to properly assess the situation you get out of the car, but unfortunately the zombies are quicker than you expected, and begin to attack you, you try to fight back but are completly outnumbered.",0xa,0xd,0xa,0xd,"We'll save the details about what happened next but lets just say it wasn't pretty",0xa,0xd,0xa,0xd,0x0
zombiesurvive: db "In order to properly assess the situation you get out of the car, but unfortunately the zombies are quicker than you expected, and begin to attack you, then you remember about the pistol that you picked up from that bedroom, so you quickly pull it out to defend yourself.",0xa,0xd,0xa,0xd,"Eventually you get the zombies under control and are finally able to clear the road and get back in your car",0xa,0xd,0x0
gameover: db "GAME OVER!",0xa,0xd,0x0
chasmobservestr: db "You get out of your car to take a closer look at the chasm",0xa,0xd,"Do you take a step closer to get a better look?(y/n)",0xa,0xd,0x0
chasmretreat: db "You decide against getting any closer and hop back in your car",0xa,0xd,0x0
chasmdeath: db "You take a step closer and you see a giant snake like creature glowing red inside the chasm. You stand there in shock, before it turns around and notices you with its massive blood red eye. You try to run back to your car to escape. But your attempt is futile, and before you know it the creature seemingly from hell is right behind you...",0xa,0xd,0xa,0xd,0x0
quitconfirm: db "Are you sure you want to quit?(Y/N)",0xa,0xd,0x0
nothingofinterest: db "You don't see anything of interest",0xa,0xd,0x0
cottagedooropen: db "You put the keys in the door and it opens up, revealing the cottages foyer",0xa,0xd,0x0
garagedooropen: db "You unlock the garage door with the keys and open the garage revealing a relatively modern looking red car. You then use the car keys to unlock the car",0xa,0xd,0x0
alreadyopenedgarage: db "You've already opened the garage door",0xa,0xd,0x0
obtainmsg: db "You pick up ",0x0
newline: db 0xa,0xd,0x0
west: db "west",0xa,0xd,0x0
east: db "east",0xa,0xd,0x0
north: db "north",0xa,0xd,0x0
road: db "road",0xa,0xd,0x0
cottage: db "cottage",0xa,0xd,0x0
garage: db "garage",0xa,0xd,0x0
paddock: db "paddock",0xa,0xd,0x0
inside: db "go inside",0xa,0xd,0x0
outside: db "go outside",0xa,0xd,0x0
foyer: db "foyer",0xa,0xd,0x0
kitchen: db "kitchen",0xa,0xd,0x0
diningroom: db "dining room",0xa,0xd,0x0
bedroom: db "bedroom",0xa,0xd,0x0
entercar: db "get in car",0xa,0xd,0x0
exitcar: db "get out of car",0xa,0xd,0x0
drivetoroad: db "drive out to the road",0xa,0xd,0x0
drivebacktogarage: db "drive back to the garage",0xa,0xd,0x0
left: db "go left",0xa,0xd,0x0
right: db "go right",0xa,0xd,0x0
goback: db "head back",0xa,0xd,0x0
leftbuilding: db "Enter the building on the left",0xa,0xd,0x0
rightbuilding: db "Enter the building on the right",0xa,0xd,0x0
citycentrestr: db "Drive into the city centre",0xa,0xd,0x0
pickupmsg0: db "You see ",0x0
pickupmsg1: db "Would you like to pick it up?(Y/N)",0xa,0xd,0x0
garageneedkey: db "The garage door seems to be locked. Maybe you can find a key somewhere.",0xa,0xd,0x0
rooms: dw paddockdirections,paddockdesc,paddockinteract, cottagedirections,cottagedesc,cottageinteract, garagedirections,garagedesc,garageinteract, roaddirections,roaddesc,roadinteract, foyerdirections,foyerdesc,foyerinteract, kitchendirections,kitchendesc,kitcheninteract, diningroomdirections,diningroomdesc,diningroominteract, bedroomdirections,bedroomdesc,bedroominteract, cargaragedirections,cargaragedesc,cargarageinteract, carroaddirections,carroaddesc,carroadinteract, chasmdirections,chasmdesc,chasminteract, outskirtsdirections,outskirtsdesc,outskirtsinteract, citycentredirections,citycentredesc,citycentreinteract, leftbuildingdirections,leftbuildingdesc,leftbuildinginteract, rightbuildingdirections,rightbuildingdesc,rightbuildinginteract, 0x0
paddockdirections: dw 0x1001,cottage,0x1002,garage,0x1003,road,0x0
paddockdesc: db "You are in a paddock, you see an old farmers cottage, with a garage right next to it. In the other direction you see a long straight country road.",0xa,0xd,0x0
paddockinteract: dw 0x1,nothingofinterest,0x0
cottagedirections: dw 0x1000,paddock,0x1002,garage,0xffff,inside,0x0
cottagedesc: db "You walk up to the front door of the cottage, the door seems to be locked",0xa,0xd,0x0
cottagedescunlocked: db "You walk back up to the front door of the cottage",0xa,0xd,0x0
cottagelookmsg: db "In an attempt to find the key you pull up the door mat, and to your luck you see the keys to the house",0xa,0xd,0x0
cottageinteract: dw 0x1,cottagelookmsg,0x2,0x1000,0x3,checkifhascottagekeys,0x0
garagedirections: dw 0x1000,paddock,0x1001,cottage,0xffff,entercar,0x0
garagedesc: db "You go up to the garage door, you try to open it but it is locked",0xa,0xd,0x0
garagedescunlocked: db "You go up to the garage door, maybe you could try opening it with the keys you have",0xa,0xd,0x0
garagedescopen: db "You go up to the garage door, and you see the red car inside",0xa,0xd,0x0
garageinteract: dw 0x3,checkifhascarkeys,0x1,garageneedkey,0x0
roaddirections: dw 0x1000,paddock,0x0
roaddesc: db "You take a look at the long straight dirt road. It seems to go on for ever in each direction. Maybe I could find a vehicle and drive around to find out where I am",0xa,0xd,0x0
roadinteract: dw 0x1,nothingofinterest,0x0
foyerdirections: dw 0x1001,outside,0x1005,kitchen,0x1006,diningroom,0x1007,bedroom,0x0
foyerdesc: db "You enter the foyer",0xa,0xd,0x0
foyerinteract: dw 0x1,foyerinteractmsg,0x0
foyerinteractmsg: db "You don't see anything of interest in the foyer. Maybe try going in one of the cottage's rooms",0xa,0xd,0x0
kitchendirections: dw 0x1004,foyer,0x0
kitchendesc: db "You enter the kitchen",0xa,0xd,0x0
kitcheninteract: dw 0x1,kitcheninteractmsg,0x2,0x1001,0x3,checkifhascarkeys,0x0
kitcheninteractmsg: db "You look around the room and see a keyring on the bench, one seems to be for the garage, and the other seems to be for a car",0xa,0xd,0x0
diningroomdirections: dw 0x1004,foyer,0x0
diningroomdesc: db "You enter the dining room",0xa,0xd,0x0
diningroominteract: dw 0x1,nothingofinterest,0x0
bedroomdirections: dw 0x1004,foyer,0x0
bedroomdesc: db "You enter the bedroom",0xa,0xd,0x0
bedroominteract: dw 0x1,bedroominteractmsg,0x2,0x1002,0x3,checkifhaspistol,0x0
bedroominteractmsg: db "You see a pistol on one of the bedside tables",0xa,0xd,0x0
cargaragedirections: dw 0x1002,exitcar,0xffff,drivetoroad,0x0
cargaragedesc: db "You sit in the car in the garage wondering what to do next",0xa,0xd,0x0
cargarageinteract: dw 0x3,turnoncar,0x0
cargarageinteractmsg: db "You put the keys in the ignition",0xa,0xd,0x0
cargarageinteractmsgafterignition: db "There isn't really anything lying around in the cabin, maybe you could try go somewhere",0xa,0xd,0x0
carroaddirections: dw 0x1008,drivebacktogarage,0x100a,left,0x100b,right,0x0
carroaddesc: db "You look both ways down the road. You wonder which way you should go.",0xa,0xd,0x0
carroadinteract: dw 0x1,cargarageinteractmsgafterignition,0x0
chasmdirections: dw 0x1009,goback,0x0
chasmdesc: db "You keep driving until you see a massive chasm in the ground blocking the rest of the road off. There is a bright firery glow coming from inside the chasm",0xa,0xd,0x0
chasminteract: dw 0x3,chasmexplore,0x0
outskirtsdirections: dw 0x1009,goback,0xffff,citycentrestr,0x0
outskirtsdesc: db "After a bit of driving you see a city in the distance.",0xa,0xd,"As you arrive at the outskirts of the city you realise that its completely infested with..",0xa,0xd,0xa,0xd,"ZOMBIES!",0xa,0xd,0x0
outskirtsdescnozombies: db "You arrive back at the outskirts of the city",0xa,0xd,0x0
outskirtsinteract: dw 0x3,zombiescene,0x0
citycentredirections: dw 0x100b,goback,0x100d,leftbuilding,0x100e,rightbuilding,0x0
citycentredesc: db "You arrive at the city center. You see two buildings that seem to be of interest, one of either side of the road",0xa,0xd,0x0
citycentreinteract: dw 0x1,citycentreinteractstr,0x0
citycentreinteractstr: db "Not much to do in the car. Maybe try enter one of those buildings",0xa,0xd,0x0
leftbuildingdirections: dw 0x100c,outside,0x0
leftbuildingdesc: db "You enter the building, nothing really seems out of the ordinary, but nothing really stands out either, maybe you should have a look around",0xa,0xd,0x0
leftbuildinginteract: dw 0x1,selfdestruct,0x1,gameover,0x3,setquittingByte,0x0
selfdestruct: db "You begin to look around the ground floor of the building. All of a sudden you hear a robotic voice comming over the buildings PA system",0xa,0xd,0xa,0xd,"WARNING! INTRUDER ALERT! SELF DESTRUCT IMMINENT!",0xa,0xd,0xa,0xd,"You run straight to the door in an attempt to escape, only to find that it has locked itself",0xa,0xd,0xa,0xd,"10,9,8,7,6,5,4,3,2,1...",0xa,0xd,0xa,0xd,"You see a flash of light accompanied by a large bang, followed immediatelly by pitch black and complete silence",0xa,0xd,0xa,0xd,0x0
rightbuildingdirections: dw 0x100c,outside,0x0
rightbuildingdesc: db "The ground floor is almost completely empty with the exception of a small table in the middle of the room with a big red button that had the word 'ESCAPE' written on it",0xa,0xd,0x0
rightbuildinginteract: dw 0x3,redbutton,0x0
pressbuttonmsg: db "Do you press the button?(Y/N)",0xa,0xd,0x0
wakeup: db "You walk up to the button and take a deep breath in before pushing it",0xa,0xd,0xa,0xd,"The moment you press the button everything goes black",0xa,0xd,0xa,0xd,"Is this death?",0xa,0xd,0xa,0xd,"You open your eyes",0xa,0xd,0xa,0xd,"You see the roof of your bedroom,",0xa,0xd,0xa,0xd,"Nope, it was only a dream.",0xa,0xd,0xa,0xd,0x0
nopush: db "You decide it really isn't a good idea going arround and pressing button that you don't know what they do",0xa,0xd,0x0
tmp0: dw 0x0
curroom: dw 0x0
reqaction: db "You can: (M)ove, (L)ook around/interact with surroundings or view (I)nventory",0xa,0xd,0x0
inventorystr: db "Here are the contents of your inventory:",0xa,0xd,0x0
itemslist: dw item0,item1,item2,0x0
item0: db "house keys",0x0
item1: db "keyring (garage and car)",0x0
item2: db "pistol",0x0
inventory: dw 0x0
times 0x100-($-inventory) dw 0x0
