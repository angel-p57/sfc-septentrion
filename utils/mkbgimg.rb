require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/img')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

arrowcolor=ImgManager.mkpixel(31,0,0)
pids=[1,2,3,*10..26,34,253]
prolog_pidmap={
  1=>35,
  2=>36,
  3=>37,
  14=>38,
  16=>39,
  19=>40,
  20=>41,
  21=>42,
}
pallets=pids.each_with_object({}){|pid,h|
  h[pid]=pallet=vmgr.getbg7basecolors(pid).map{|r|
    ImgManager.mkpixel(*r)
  }
  next if pid==253
  pallet[7]=arrowcolor if pid>3
  if pid==24  # theater
    vmgr.getbg7rotcolors(pid,0,true).each_with_index{|r,i|
      pallet[56+i]=ImgManager.mkpixel(*r)
    }
  end
  vmgr.getbg7rotcolors(pid,0).each_with_index{|r,i|
    pallet[113+i]=ImgManager.mkpixel(*r)
  }
}
tiles2file=->tiles,pid,file,dotsize=3{
  warn "* invalid tile number #{tiles.size} *" if tiles.size%16!=0
  rown=tiles.size/16
  pallet=pallets[pid]
  canvas=TiledCanvas.new(8,dotsize,rown,16)
  rown.times{|r|
    16.times{|c|
      win=canvas.makewindow(r,c)
      t=tiles[r*16+c]
      8.times{|i|
        8.times{|j|
          colid=t[i][j]&0x7f
          win[i,j]=pallet[colid]
        }
      }
    }
  }
  canvas.save(file)
}

pids.each{|pid|
  bgtiles=vmgr.getmode7tiles(
    pid,
    pid==253 ? 0x3000 : 0x4000
  )
  tiles2file[
    bgtiles,
    pid,
    pid==253 ? "bgbase-map.png" : "bgbase-%02d.png"%pid
  ]
  prolog_pid=prolog_pidmap[pid] or next
  bgtiles_ex=vmgr.getmode7tiles(prolog_pid, 0x1000)
  tiles2file[bgtiles_ex,pid,"bgex-%02d.png"%pid]
}
