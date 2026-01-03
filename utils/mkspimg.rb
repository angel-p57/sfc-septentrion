require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/img')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

blank=ImgManager.mkpixel(16,16,16)
pallets=9.times.map{|pid|
  vmgr.getspcolors(pid < 8 ? pid : 0).map{|r|
    r && ImgManager.mkpixel(*r)
  } << blank
}
pallets[8][12,2]=[
  ImgManager.mkpixel(31,31,31),
  ImgManager.mkpixel(0,0,31)
]
btile=[[16]*8]*8

tiles2file=->tiles,file,pid,dotsize=3{
  warn "* invalid tile number #{tiles.size} *" if tiles.size%16!=0
  rown=tiles.size/16
  canvas=TiledCanvas.new(8,dotsize,rown,16)
  rown.times{|r|
    16.times{|c|
      win=canvas.makewindow(r,c)
      t=tiles[r*16+c] || btile
      8.times{|i|
        8.times{|j|
          color=pallets[pid][t[i][j]] or next
          win[i,j]=color
        }
      }
    }
  }
  canvas.save(file)
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
