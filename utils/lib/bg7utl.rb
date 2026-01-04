class BG7Manager
  attr_reader :pids
  def initialize(vmgr,imgmgr)
    @vmgr=vmgr
    @imgmgr=imgmgr
    @arrowcolor=ImgManager.mkpixel(31,0,0)
    @pids=[1,2,3,*10..26,34,253]
    @prolog_pidmap={
      1=>35,
      2=>36,
      3=>37,
      14=>38,
      16=>39,
      19=>40,
      20=>41,
      21=>42,
    }
    @pallets={}
  end
  def haveanothertile(pid)
    @prolog_pidmap.key?(pid)
  end
  def getpallet(pid)
    pallet=@pallets[pid] and return pallet
    pallet=@pallets[pid]=@vmgr.getbg7basecolors(pid).map{|r|
      @imgmgr.mkpixel(*r)
    }
    if pid==253
      pallet[94]=@imgmgr.mkpixel(31,0,0) # ボイラー室前入り口
      return pallet
    end
    pallet[7]=@arrowcolor if pid>3
    if pid==24  # theater
      @vmgr.getbg7rotcolors(pid,0,true).each_with_index{|r,i|
        pallet[56+i]=@imgmgr.mkpixel(*r)
      }
    end
    @vmgr.getbg7rotcolors(pid,0).each_with_index{|r,i|
      pallet[113+i]=@imgmgr.mkpixel(*r)
    }
    return pallet
  end
  def getcoloredtiles(pid,prologue=false)
    bgtiles=@vmgr.getmode7tiles(
      pid,
      pid==253 ? 0x3400 : 0x4000
    )
    if prologue && haveanothertile(pid)
      bgtiles[192,64]=@vmgr.getmode7tiles(@prolog_pidmap[pid], 0x1000)
    end
    pallet=getpallet(pid)
    bgtiles.map{|t|
      t.map{|r|
        r.map{|colid|
          pallet[colid&0x7f]
        }
      }
    }
  end
end
