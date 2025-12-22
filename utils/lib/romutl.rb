class SepRom
  DEFAULT_ROM_PATH='sep.sfc'
  BANK_RANGE=0x80..0x9f
  ADDRESS_RANGE=0x8000..0xffff
  BANK_SIZE=ADDRESS_RANGE.last-ADDRESS_RANGE.first+1
  def self.addr2off(bank,addr)
    if BANK_RANGE===bank && ADDRESS_RANGE===addr
      return (bank-BANK_RANGE.first)*BANK_SIZE + addr-ADDRESS_RANGE.first
    end
    raise IndexError.new(
      "invalid address bank=0x%02x, addr=0x%04x" % [bank, addr]
    )
  end
  def initialize(file=DEFAULT_ROM_PATH)
    romf=File.open(file, "rb")
    @rawdata=romf.read().bytes
    romf.close
  end
  def getbytes(bank,addr,len)
    if len>0 && addr+len<=ADDRESS_RANGE.last+1
      return @rawdata[self.class.addr2off(bank,addr),len]
    end
    raise IndexError.new(
      "invalid length 0x%04x for bank=0x%02x, addr=0x%04x" % [len,bank,addr]
    )
  end
  def getwords(bank,addr,len)
    bytes=getbytes(bank,addr,len*2)
    (0...len).map{|i|
      bl,bh=bytes[i*2,2]
      bh<<8|bl
    }
  end
  def getlwords(bank,addr,len)
    bytes=getbytes(bank,addr,len*3)
    (0...len).map{|i|
      bl,bh=bytes[i*3,2]
      [bytes[i*3+2],bh<<8|bl]
    }
  end
  def getbyte(bank,addr)
    getbytes(bank,addr,1)[0]
  end
  def getword(bank,addr)
    getwords(bank,addr,1)[0]
  end
  def getlword(bank,addr)
    getlwords(bank,addr,1)[0]
  end
  def getline(bank,addr,delimiter=0xff,delim_include=false)
    off=self.class.addr2off(bank,addr)
    ret=[]
    0.step(ADDRESS_RANGE.last-addr){|i|
      b=@rawdata[off+i]
      if b==delimiter
        ret << b if delim_include
        return ret
      end
      ret << b
    }
    raise EOFError.new(
      "delimiter %02x not found in bank %02x, from address=%04x" % [delimiter,bank,addr]
    )
  end
  def uncompress(bank,addr,verbose=false)
    ibase=self.class.addr2off(bank,addr)
    ilim=ADDRESS_RANGE.last-addr
    rbytes=[]
    i=j=0
    getb=->{
      raise "bank boundary violated i={#i},j={#j}" if i>ilim
      b=@rawdata[ibase+i]
      i+=1
      b
    }
    setb=->b{
      rbytes[j]=b
      j+=1
    }
    copy=->a,off{
      (a+1).times{
        rbytes[j]=rbytes[j-off]
        j+=1
      }
    }
    buf=0
    sbits=0
    fill=->{
      ibak=i
      bl=getb[]
      bh=getb[]
      w=(bh<<8)|bl
      buf|=w<<(16-sbits)
      sbits+=16
      warn "fill @#{ibak}" if verbose
    }
    getbw=->{
      buf>>16
    }
    discard=->d{
      return if d==0
      buf=(buf<<d)&0xffffffff
      sbits-=d
      fill[] if sbits<16
    }
    judge1=->{
      w=getbw[]
      case w
      when      0... 0x200; [(w>>2)|0x80, 13]
      when  0x200... 0x400; [w>>3, 12]
      when  0x400... 0x800; [w>>5, 10]
      when  0x800...0x1000; [w>>7, 8]
      when 0x1000...0x2000; [w>>9, 6]
      when 0x2000...0x4000; [w>>11, 4]
      when 0x4000...0x8000; [w>>13, 2]
      else;                 [1, 0]
      end
    }
    judge2=->{
      w=getbw[] & 0x7fff
      case w
      when      0... 0x800; [w>>9, 7]
      when  0x800... 0xc00; [(w>>8)-4, 8]
      when  0xc00...0x1800; [(w>>7)-0x10, 9]
      when 0x1800...0x3000; [(w>>6)-0x40, 10]
      else;                 [(w&0xfff|0x1000)>>(8-(w>>12)), 8+(w>>12)]
      end
    }
    fill[]
    begin
      loop{
        warn "getf @#{i}" if verbose
        cb=getb[]
        7.downto(0){|k|
          if cb[k]>0
            warn "copyraw @#{i} -> @#{j}" if verbose
            setb[getb[]]
          else
            p1,d1=judge1[]
            break if p1==0xff
            discard[d1]
            p2,d2=judge2[]
            discard[d2]
            if verbose
              warn "repeat @#{j} from -#{p2} by #{p1+1}, consume #{d1+d2}"
              bufs=("%032b"%buf)[0...sbits]
              warn "pooled #{bufs} ( #{sbits} bits )"
            end
            copy[p1,p2+1]
          end
        } or break
      }
    rescue => e
      puts "   * error #{e} *"
    end
    [rbytes, i]
  end
end
