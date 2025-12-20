require 'set'

class EventManager
  EVID_RANGE=0..254
  RAW_EVIDS = Set.new([
    3,7,24,34,38,54,56,
    65,70,85,99,100,104,120,
    *(128..139),155,156,157,158,*(160..170),178,
    249,250,
  ])
  EXCL_EVIDS = Set.new([
    19,24,30,50,54,62,82,85,94,115,120,126,155,204,241
  ])
  HIEV_HERO_TAB=[
    0,0,0,1,1,1,2,2,
    2,3,3,3,0,0,0,0,
    0,0,0,0,3,3,3,3,
    3,1,1,1,1,nil,nil,nil,
    nil,nil,1,1,1,1,2,2,
    2,nil,2,2,nil,nil,nil,nil,
    nil,3,1,3,0,1,2,
  ]
  def self.get_hero(evid)
    evid < 128 ? evid/32 :
    evid >= 200 ? HIEV_HERO_TAB[evid-200] : nil
  end
  Event=Struct.new(
    :bank, :addr, :msize, :rsize, :rej, :raw, :pflag, :hero,
    :msgid_base, :rnum, :chars, :cid_start, :cid_base,
    :rchunks, :pos, :cmds, :bytes
  ){
    # WIP
  }
  def initialize(romobj)
    @rom=romobj
  end
  def get(evid)
    raise IndexError.new("#{evid} is out of range") unless EVID_RANGE===evid
    return nil if evid==90
    bank,base=0x9e,0x9c20
    poff1=@rom.getword(bank, base+evid*2)
    if evid==90 || evid==254
      poff2=0xfe48
    else
      poff2=@rom.getword(bank, base+evid*2+2)
    end
    return nil if poff1==poff2
    bank=evid<=90 ? 0x9f : 0x9e
    raw=RAW_EVIDS.include?(evid)
    if raw
      rsize=msize=poff2-poff1
      bytes=@rom.getbytes(bank, poff1, msize)
    else
      bytes,msize=@rom.uncompress(bank, poff1)
      rsize=bytes.size
    end
    return nil if rsize<64  # empty event
    bytes.pop(rsize%16) if rsize%16>0
    msgid_base = (bytes[1]<<8)|bytes[0]
    cnum = bytes[2]
    rnum = bytes[3]
    warn "#{evid}: invalid cnum/rnum" if cnum>4 || rnum>cnum
    chars=bytes[4,cnum]
    cid_start = ((bytes[0x2d]&0x7f)<<8)|bytes[0x2c]
    cid_start = nil if cid_start<=0
    cid_base = (bytes[0x2f]<<8)|bytes[0x2e]
    rchunks=bytes[0x28,cnum].map{|cid| cid>0 ? cid+cid_base : nil }
    pflag = bytes[0x2d]&0x80 > 0
    hid = pflag ? 4 : self.class.get_hero(evid)
    hero = hid && %W(c r l j p)[hid]
    pos=4.times.map{|i|
      r=cnum.times.map{|j|
        bytes[8*i+j*2+8,2].map{|v| v*16 }
      }
      cnum==0 || r[0][0]==0 && r[0][1]==0 ? nil : r
    }
    cmds=bytes[0x30..-1].each_slice(16).map{|r|
      r.each_slice(4).to_a
    }
    Event.new(
      bank,
      poff1,
      msize,
      rsize,
      EXCL_EVIDS.include?(evid),
      raw,
      pflag,
      hero,
      msgid_base,
      rnum,
      chars,
      cid_start,
      cid_base,
      rchunks,
      pos,
      cmds,
      bytes
    )
  end
end
