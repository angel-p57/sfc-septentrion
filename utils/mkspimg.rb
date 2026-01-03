require 'rmagick'
require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/img')

mkpixel=->r,g,b,t=false{ ImgManager.mkpixel(r,g,b,t) }

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

bg=mkpixel[10,10,10,true]
blank=mkpixel[16,16,16]
pallets=9.times.map{|pid|
  vmgr.getspcolors(pid < 8 ? pid : 0).map{|r|
    r && mkpixel[*r]
  } << blank
}
pallets[8][12,2]=[mkpixel[31,31,31],mkpixel[0,0,31]]
lcol=mkpixel[ 0,20,20]
btile=[[16]*8]*8

tiles2file=->tiles,file,pid,dotsize=3{
  warn "* invalid tile number #{tiles.size} *" if tiles.size%16!=0
  rown=tiles.size/16
  csizeh=128*dotsize+17
  csizev=8*rown*dotsize+rown+1
  canvas=csizev.times.flat_map{|i|
    i%(dotsize*8+1)==0 ? [lcol]*csizeh : [lcol,*[bg]*(8*dotsize)]*16+[lcol]
  }
  (rown*16).times{|i|
    t=tiles[i] || btile
    r0=i/16*(dotsize*8+1)+1
    c0=i%16*(dotsize*8+1)+1
    8.times{|j|
      r=r0+j*dotsize
      8.times{|k|
        b=r*csizeh+c0+k*dotsize
        color=pallets[pid][t[j][k]] or next
        dotsize.times{|n1|
          dotsize.times{|n2|
            canvas[b+csizeh*n1+n2]=color
          }
        }
      }
    }
  }
  img=Magick::Image.new(csizeh,csizev)
  img.store_pixels(0,0,csizeh,csizev,canvas)
  img.write(file)
}

sptiles=vmgr.get4bpptiles8(0)
sptiles[448...480]=[btile]*32
8.times{|pid|
  tiles2file[sptiles, "spbase-p#{pid}.png", pid]
}
sptiles_ex=[*43..55,314,315,327,335].flat_map{|i|
  tiles=vmgr.get4bpptiles8(i)
  i==335 ? tiles : tiles+[btile]*16
}
8.times{|pid|
  tiles2file[sptiles_ex, "spex-p#{pid}.png", pid]
}
sptiles_map=vmgr.get4bpptiles8(312)
tiles2file[sptiles_map, "spex-map-p0+.png", 8]
