class VRAMmgr
  PTR_BANK=0x80
  PTR_BASE=0xf872
  def initialize(romobj)
    @rom=romobj
  end
  def getraw_unc(id, another=false)
    if another
      raise NotImplementedError.new
    else
      @rom.uncompress(*@rom.getlword(PTR_BANK,PTR_BASE+id*3))[0]
    end
  end
  def get2bpptiles8(id)
    raw=getraw_unc(id)
    warn "invalid raw size #{raw.size} for id #{id}" unless raw.size%16==0
    tiles=raw.each_slice(16).map{|bs|
      bs.each_slice(2).map{|(bl,bh)|
        8.times.map{|j|
          bl[7-j]+bh[7-j]*2
        }
      }
    }
  end
  def get2bpptiles16(id)
    tiles8=get2bpptiles8(id)
    warn "invalid tile number #{tiles8.size} for id #{id}" unless tiles8.size%16==0
    (tiles8.size/4).times.map{|i|
      parts=[0,1,16,17].map{|j| tiles8[i/8*32+i%8*2+j] }
      parts[0].zip(parts[1]).map{|(r1,r2)| r1+r2 } + parts[2].zip(parts[3]).map{|(r1,r2)| r1+r2 }
    }
  end
end
