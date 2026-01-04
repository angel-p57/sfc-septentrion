class VRAMmgr
  PTR_BANK=0x80
  PTR_BASE=0xf872
  PTR_BASE_ANOTHER=0xfe4b
  def initialize(romobj)
    @rom=romobj
    @tmanother_map={
      74=>0, 75=>1,
      76=>2, 77=>3,
      78=>4, 79=>5,
      80=>6, 81=>7,
      82=>8,
      87=>9, 88=>10, 89=>11,
      90=>12,
      108=>13, 109=>14,
      112=>15, 113=>16, 114=>17,
      115=>18, 116=>19, 117=>20,
      123=>21, 124=>22,
      133=>23, 134=>24,
      158=>25
    }
  end
  def getraw_unc(id, another=false)
    if another
      id_conv=@tmanother_map[id] or raise IndexError.new("no another tilemap for tmid #{id}")
      @rom.uncompress(*@rom.getlword(PTR_BANK,PTR_BASE_ANOTHER+id_conv*3))[0]
    else
      @rom.uncompress(*@rom.getlword(PTR_BANK,PTR_BASE+id*3))[0]
    end
  end
  def gettmap(id, another=false)
    another ? getraw_unc(id, true) : getraw_unc(id+57)
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
  def get4bpptiles8(id)
    raw=getraw_unc(id)
    warn "invalid raw size #{raw.size} for id #{id}" unless raw.size%32==0
    tiles=raw.each_slice(32).map{|bs|
      8.times.map{|i|
        b0,b1,b2,b3=bs[i*2],bs[i*2+1],bs[i*2+16],bs[i*2+17]
        8.times.map{|j|
          b0[7-j]+b1[7-j]*2+b2[7-j]*4+b3[7-j]*8
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
  def getmode7tiles(id, size=nil)
    raw=getraw_unc(id)
    if size
      raise "invalid size #{size} for id #{id}" if size>raw.size
      raw.pop(raw.size-size) if size<raw.size
    end
    warn "invalid raw size #{raw.size} for id #{id}" unless raw.size%64==0
    raw.each_slice(64).map{|r|
      r.each_slice(8).to_a
    }
  end
  def word2r5g5b5(x)
    [x&31, (x>>5)&31, x>>10]
  end
  def getcgsetaddr(sid)
    bank,base=@rom.getlword(0x80, 0xf800)
    addr=@rom.getword(bank, base+sid*2)
    [bank,addr+2]
  end
  def getspcolors(pid)
    bank,addr=getcgsetaddr(1)
    words=@rom.getwords(bank, addr+2+pid*30, 15)
    [
      nil,
      *words.map{|x| word2r5g5b5(x) }
    ]
  end
  def getbg7basecolors(pid)
    case pid
    when 1..3
      bank,addr=0x8b,0x8000+(pid-1)*0xf0
    when 11,13
      bank,addr=getcgsetaddr(0)
    when 34
      bank,addr=0x86,0xef00+(27-10)*240
    when 10..26
      bank,addr=0x86,0xef00+(pid-10)*240
    when 253  # map
      bank,addr=getcgsetaddr(3)
    else
      raise ValueError.new("wrong plase id #{pid}")
    end
    (0..7).flat_map{|pid|
      words=@rom.getwords(bank, addr+pid*30, 15)
      [
        [0,0,0],
        *words.map{|x| word2r5g5b5(x) }
      ]
    }
  end
  def getbg7rotcolors(pid,vid,theater=false)
    bank=0x8f
    if pid==24 && theater
      addroff=5040
      cnum=8
    else
      addroff=240*(
        pid==34 ? 17 :
        pid>=10 ? pid-10 : pid+17
      )
      cnum=15
    end
    @rom.getwords(
      bank,
      0x8000+addroff+vid*cnum*2,
      cnum
    ).map{|x|
      word2r5g5b5(x)
    }
  end
  def getmainblockmap(i)
    bank=0x92
    bytes=@rom.getbytes(bank,0x8000+i*32,32)
    if i==0
      bytes.each_slice(16).map{|r| r[3..12] }
    else
      bytes.each_slice(16).map{|r| r[2..13] }
    end
  end
  TmapInfo=Struct.new(:pid,:rown,:coln,:tmbase){
    # WIP
  }
  def gettmapinfo(rid)
    bank=0x92
    bytes=@rom.getbytes(bank,0x8060+rid*3,3)
    TmapInfo.new(bytes[0],bytes[1]&0xf,bytes[1]>>4,bytes[2]+43)
  end
end
