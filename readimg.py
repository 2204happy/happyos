import os
import sys

if len(sys.argv) < 3:
  print("Usage python3 readimg.py [inputimg] [outputrootdir]")
else:
  root = sys.argv[2]
  if root[-1] == "/":
    root = root[0:-1]
  os.system("mkdir "+root)
  f = open(sys.argv[1],"rb")
  inp = f.read()
  f.close()
  fs = inp[2560:3584]
  fsptr = 0
  files = []
  dirs = {0:[0,None,True]}
  while fs[fsptr] != 0:
    if fs[fsptr] == 3:
      dirid = fs[fsptr+1]
      pdirid = fs[fsptr+3]
      dirname = ""
      i = 4
      while fs[fsptr+i] != 0:
        dirname = dirname + chr(fs[fsptr+i])
        i+=1
      dirs[dirid] = [pdirid,dirname,False]
    if fs[fsptr] == 2:
      block = fs[fsptr+1]
      size = fs[fsptr+2]
      pdirid = fs[fsptr+3]
      fname = ""
      i = 4
      while fs[fsptr+i] != 0:
        fname = fname + chr(fs[fsptr+i])
        i+=1
      files.append([block,size,pdirid,fname])
    fsptr+=16

  dirsmade = 0
  while dirsmade < len(dirs)-1:
    for dr in dirs:
      d = dirs[dr]
      if d[2] == 0:
        if d[0] == 0:
          os.system("mkdir "+root+"/"+d[1])
          d[2] = True
          dirsmade+=1
        else:
          cancreate = True
          pdir = dirs[d[0]]
          path = d[1]
          while cancreate and pdir[1] != None:
            path = pdir[1] + "/" + path
            cancreate = pdir[2]
            pdir = dirs[pdir[0]]
          if cancreate:
            os.system("mkdir "+root+"/"+path)
            dirsmade+=1
            d[2] = True
  for fAtrbs in files:
    path = fAtrbs[3]
    pdir = fAtrbs[2]
    while pdir != 0:
      pdiratrbs = dirs[pdir]
      path = pdiratrbs[1] + "/" + path
      pdir = pdiratrbs[0]
    fBytes = inp[512*fAtrbs[0]:512*(fAtrbs[0]+fAtrbs[1])]
    fBytes = bytearray(fBytes)
    while fBytes[-1] == 0:
      del fBytes[-1]
    f = open(root+"/"+path,"wb")
    f.write(fBytes)
    f.close()
