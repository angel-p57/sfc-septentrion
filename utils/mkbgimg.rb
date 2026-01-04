require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/bg7utl')
require_relative('lib/img')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)
bg7mgr=BG7Manager.new(vmgr,ImgManager)

tiles2file=->tiles,file,dotsize=3{
  warn "* invalid tile number #{tiles.size} *" if tiles.size%16!=0
  rown=tiles.size/16
  canvas=TiledCanvas.new(8,dotsize,rown,16)
  rown.times{|r|
    16.times{|c|
      win=canvas.makewindow(r,c)
      t=tiles[r*16+c]
      8.times{|i|
        8.times{|j|
          win[i,j]=t[i][j]
        }
      }
    }
  }
  canvas.save(file)
}

bg7mgr.pids.each{|pid|
  tiles2file[
    bg7mgr.getcoloredtiles(pid),
    pid==253 ? "bgbase-map.png" : "bgbase-%02d.png"%pid
  ]
  bg7mgr.haveanothertile(pid) or next
  tiles2file[
    bg7mgr.getcoloredtiles(pid,true)[192,64],
    "bgex-%02d.png"%pid
  ]
}
