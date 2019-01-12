dd if=/dev/zero of=os.img bs=512 count=63
nasm boot.asm
dd if=boot of=os.img conv=notrunc
rm boot
nasm osmain.asm
dd if=osmain of=os.img conv=notrunc seek=1
rm osmain
dd if=fs.bin of=os.img conv=notrunc seek=5
nasm quickhello.asm
dd if=quickhello of=os.img conv=notrunc seek=7
rm quickhello
dd if=textdoc of=os.img conv=notrunc seek=8
dd if=stantwt of=os.img conv=notrunc seek=9
