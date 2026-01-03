require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/img')

mkpixel=->r,g,b,t=false{ ImgManager.mkpixel(r,g,b,t) }
pallet=[
  nil,
  mkpixel[ 8, 3,31],
  mkpixel[ 3, 1,31],
  mkpixel[31,31,31],
  mkpixel[20,20,20],
]
lcol=mkpixel[ 0,20,20]
bg=mkpixel[0,0,0]
blank=mkpixel[31,31,31]
btile=[[4]*16]*16

tiles2file=->tiles,file,dotsize=2{
  csize=256*dotsize+17
  canvas=csize.times.flat_map{|i|
    i%(dotsize*16+1)==0 ? [lcol]*csize : [lcol,*[bg]*(16*dotsize)]*16+[lcol]
  }
  (240*dotsize+16...csize).each{|i|
    canvas[i*csize+192*dotsize+13...i*csize+csize]=[blank]*(64*dotsize+4)
  }
  252.times{|i|
    t=tiles[i] || btile
    r0=i/16*(dotsize*16+1)+1
    c0=i%16*(dotsize*16+1)+1
    16.times{|j|
      r=r0+j*dotsize
      16.times{|k|
        b=r*csize+c0+k*dotsize
        color=pallet[t[j][k]] or next
        dotsize.times{|n1|
          dotsize.times{|n2|
            canvas[b+csize*n1+n2]=color
          }
        }
      }
    }
  }
  ImgManager.save(file,canvas,csize,csize)
}

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

basetiles=vmgr.get2bpptiles16(57)

d1tiles=basetiles[0,144]+vmgr.get2bpptiles16(296)
tiles2file[d1tiles, "font1.png"]

d2tiles=basetiles[0,174]+[nil]*2+vmgr.get2bpptiles16(334)
d2tiles+=d2tiles[48...72]
tiles2file[d2tiles, "font2.png"]

tiles2file[basetiles, "font3.png"]

d4tiles=basetiles[0,174]+[nil]*2+vmgr.get2bpptiles16(297)
tiles2file[d4tiles, "font4.png"]

d5tiles=basetiles[0,112]+vmgr.get2bpptiles16(298)
tiles2file[d5tiles, "font5.png"]
