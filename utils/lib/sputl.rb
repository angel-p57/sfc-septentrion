class PartsMgr
  PTR_BANK=0x80
  PTR_BASE=0xf812
  CGID_RANGE=0..26
  Part=Struct.new(:tid, :pid, :x, :y, :quad, :hrev, :vrev) {
    #WIP
  }
  @@diffidmap={
    0=>0, 1=>1, 2=>2, 5=>3, 
  }
  def initialize(romobj)
    @rom=romobj
  end
  def getpaddrtab(cgid)
    raise IndexError.new("cgid #{cgid} out of range ( #{CGID_RANGE} )") unless CGID_RANGE===cgid
    bank,base=@rom.getlword(PTR_BANK, PTR_BASE+cgid*3)
    pidrange=0..(cgid>=25 ? 32 : 256)
    prev=nil
    pidrange.each_with_object({}){|pid,tab|
      addr=@rom.getword(bank,base+pid*2)
      if prev && (addr<prev || addr-prev>0x100)
        tab[pid-1]=[bank,prev] if prev
        break tab
      end
      next if prev==addr
      tab[pid-1]=[bank,prev] if prev
      prev=addr
    }
  end
  def getparts_aux(bank, addr, did, off=0, dx=0, dy=0, n=255)
    parts=[]
    xinf=yinf=256
    xsup=ysup=-256
    while n>0
      flag,p1,p2,y,x=@rom.getbytes(bank,addr,5)
      x-=256 if x>=128
      y-=256 if y>=128
      if flag>=0xc0
        break
      elsif flag>=0x40
        xi,xs,yi,ys,aparts=getparts_aux(bank,(p2<<8)|p1,did,parts.size,dx+x,dy+y,flag&63)
        parts+=aparts
        xinf=xi if xi<xinf
        yinf=yi if yi<yinf
        xsup=xs if xs>xsup
        ysup=ys if ys>ysup
        break if flag>=0x80
      else
        if did
          i=off+parts.size
          j=@@diffidmap[i]
          if j
            ddy,ddx,dp1,dp2=@rom.getbytes(0x9e,0x8000+did*16+j*4,4)
            x+=ddx>=128 ? 128-ddx : ddx
            y+=ddy>=128 ? 128-ddy : ddy
            p1^=dp1
            p2^=dp2
          end
        end
        part=Part.new(
          p2&1==0 ? p1 : p1+256,
          (p2&0xe)>>1,
          dx+x,
          dy+y,
          flag&1!=0,
          p2&0x40!=0,
          p2&0x80!=0
        )
        parts<<part
        n-=1
        xs=part.x + (part.quad ? 16 : 8)
        ys=part.y + (part.quad ? 16 : 8)
        xinf=part.x if part.x<xinf
        yinf=part.y if part.y<yinf
        xsup=xs if xs>xsup
        ysup=ys if ys>ysup
      end
      addr+=5
    end
    [xinf,xsup,yinf,ysup,parts]
  end
  def getparts(bank, addr, did=nil)
    getparts_aux(bank, addr, did)
  end
end
