import os
import sys
import math

if len(sys.argv) < 3:
  print("Usage: python3 makeing.py [rootdir] [outputimg]")
else:  
  root = sys.argv[1]
  if root[-1] == "/":
    root = root[0:-1]
    
  #update /src
  os.system("rm -r "+root+"/src")
  os.system("cp -r src "+root)
  
  os.system("rm -r "+root+"/bin")
  os.system("rm -r "+root+"/sys")
  
  os.system("mkdir "+root+"/bin")
  os.system("mkdir "+root+"/sys")
  
  #assemble os files
  os.system("nasm src/boot.asm -o "+root+"/sys/boot.sys")
  #os.system("nasm src/osmain.asm -o "+root+"/sys/os.sys")
  os.system("nasm src/kernel.asm -o "+root+"/sys/kernel.sys")
  
  #assemble other files
  f = open("toassemble.csv")
  lines = f.readlines()
  f.close()
  for line in lines:
    line = line.split(",")
    os.system("nasm "+line[0]+" -o "+root+line[1])
  
  blockamnt = 2880
  output = bytearray([0]*(512*blockamnt))
  fs = bytearray([0]*(3072))
  initfsstr = b"\x02\x01\x00\xff\xff\x00\x00\x01boot.sys\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00\xff\xff\x01\x00\x02kernel.sys\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x03\x00\xff\xff\x03\x00\x06fs.sys\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\xff\xff\x00\x00\x00\x00\x00sys\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  

  fsptr = 0
  for i in range(len(initfsstr)):
    fs[i] = initfsstr[i]
    fsptr+=1
  blkptr = 9
  
  #crawl root directory (and its sub directories)
  nextdirid = 65534
  dirlist = {root:[0,root,root],root+"/sys":[65535,"sys",root]}#key is full path, index 0 is id, index 1 is dir name, index 2 is root dir (full path)
  filelist = []
  for r,dirs,files in os.walk(root):  
    for d in dirs:
      if not (d == "sys" and r == root):
        dirlist[r+'/'+d] = [nextdirid,d,r]
        nextdirid-=1
    for f in files:
      filelist.append([f,r])
  
  for dr in dirlist:
    if dr != root and dr != root+"/sys":
      d = dirlist[dr]
      if len(d[1]) > 23:
        print("dir name too long, truncating")
        d[1] = d[1][0:23]
      fs[fsptr] = 3
      fs[fsptr+1] = d[0]&255
      fs[fsptr+2] = (d[0]>>8)&255
      fs[fsptr+3] = dirlist[d[2]][0]&255
      fs[fsptr+4] = (dirlist[d[2]][0]>>8)&255
      for i in range(len(d[1])):
        fs[fsptr+8+i] = ord(d[1][i])
      fsptr+=32
  
  filelist.remove(["boot.sys",root+"/sys"])
  filelist.remove(["kernel.sys",root+"/sys"])
  try:
    filelist.remove(["fs.sys",root+"/sys"])
  except:
    pass
  
  nextFileID = 4
  
  for filei in filelist:
     f = open(filei[1]+'/'+filei[0],"rb")
     fstream = f.read()
     f.close()
     if len(filei[0]) > 23:
       print("file name too long, truncating")
       filei[0] = filei[0][0:23]
     size = math.ceil(len(fstream)/512)
     #size = ((len(fstream)-(len(fstream)%512))/512)+1
     fs[fsptr] = 2
     fs[fsptr+1] = int(nextFileID)&255
     fs[fsptr+2] = (int(nextFileID)>>8)&255
     fs[fsptr+3] = (dirlist[filei[1]][0])&255
     fs[fsptr+4] = (dirlist[filei[1]][0]>>8)&255
     fs[fsptr+5] = int(blkptr)&255
     fs[fsptr+6] = (int(blkptr)>>8)&255
     fs[fsptr+7] = int(size)
     for i in range(len(filei[0])):
       fs[fsptr+8+i] = ord(filei[0][i])
     for i in range(len(fstream)):
       output[int(((blkptr)*512)+i)] = fstream[i]
     blkptr+=size
     fsptr+=32
     nextFileID+=1
  fs[fsptr] = 1
  fs[fsptr+1] = int(blkptr)
  fs[fsptr+2] = min(int(blockamnt - blkptr),255)
 
  
  #write new fs.sys
  f = open(root+"/sys/fs.sys","wb")
  f.write(fs)
  f.close()
  
  #write boot.sys and os.sys to output string
  sysfiles = [[root+"/sys/boot.sys",0],[root+"/sys/kernel.sys",512],[root+"/sys/fs.sys",1536]]
  for sysfile in sysfiles:
    f = open(sysfile[0],"rb")
    tmp = f.read()
    f.close()
    for i in range(len(tmp)):
      output[sysfile[1]+i] = tmp[i]
  
  f = open(sys.argv[2],"wb")
  f.write(output)
  f.close()
