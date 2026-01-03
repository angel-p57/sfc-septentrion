require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/img')

pallet=[
  ImgManager.mkpixel( 0, 0, 0),
  ImgManager.mkpixel( 8, 3,31),
  ImgManager.mkpixel( 3, 1,31),
  ImgManager.mkpixel(31,31,31),
  ImgManager.mkpixel(20,20,20),
  ImgManager.mkpixel(31,31,31)
]
btile=[[4]*16]*16
wtile=[[5]*16]*16

tiles2file=->tiles,file,dotsize=2{
  canvas=TiledCanvas.new(16,dotsize,16,16)
  256.times{|k|
    t=k<252 ? tiles[k] || btile : wtile
    win=canvas.makewindow(k/16,k%16)
    16.times{|i|
      16.times{|j|
        color=pallet[t[i][j]] or next
        win[i,j]=color
      }
    }
  }
  canvas.save(file)
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
