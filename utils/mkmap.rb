require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/bg7utl')
require_relative('lib/img')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)
bg7mgr=BG7Manager.new(vmgr,ImgManager)

rline=ImgManager.mkpixel(31,0,0)

tiles2file=->tbase,tmaps,bmap,file,dotsize=2{
  hbn=bmap[0].size
  canvas=TiledCanvas.new(8,dotsize,64,32*hbn,false)
  2.times{|br|
    hbn.times{|bc|
      tmap=tmaps[bmap[br][bc]-1]
      32.times{|r|
        32.times{|c|
          t=tbase[tmap[r*32+c]]
          win=canvas.makewindow(br*32+r,bc*32+c)
          8.times{|i|
            8.times{|j|
              win[i,j]=t[i][j]
            }
          }
        }
        8.times{|i|
          canvas[br*32+r,bc*32,i,0,0,0]=rline
        }
      }
      32.times{|c|
        8.times{|j|
          canvas[br*32,bc*32+c,0,j,0,0]=rline
        }
      }
    }
  }
  canvas.save(file)
}

(0..2).each{|i|
  bmap=vmgr.getmainblockmap(i)
  [false,true].each{|prologue|
    tiles=bg7mgr.getcoloredtiles(i+1,prologue)
    tmaps=(0..30).map{|j| vmgr.gettmap(j+(prologue ? 7 : 200)) }
    idoff1=prologue ? 0 : 52
    case i
    when 0
      tmaps[0]=vmgr.gettmap(185+idoff1)
      tmaps[20]=vmgr.gettmap(179+idoff1)
      tmaps[21]=vmgr.gettmap(180+idoff1)
    when 1
      tmaps[0]=vmgr.gettmap(7) if prologue
      tmaps[24]=vmgr.gettmap(184+idoff1)
    when 2
      tmaps[5]=vmgr.gettmap(184+idoff1)
      tmaps[6]=vmgr.gettmap(prologue ? 10 : 203)
      tmaps[20]=vmgr.gettmap(180+idoff1)
      tmaps[21]=vmgr.gettmap(181+idoff1)
      tmaps[22]=vmgr.gettmap(182+idoff1)
      tmaps[23]=vmgr.gettmap(183+idoff1)
    end
    tiles2file[tiles,tmaps,bmap,"mapmain-#{i}#{prologue ? ?p : ''}.png"]
  }
}
