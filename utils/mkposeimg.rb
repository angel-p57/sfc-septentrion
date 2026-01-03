require 'rmagick'
require_relative('lib/romutl')
require_relative('lib/vramutl')
require_relative('lib/sputl')
require_relative('lib/img')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

mkpixel=->r,g,b,t=false{ ImgManager.mkpixel(r,g,b,t) }
bg=mkpixel[10,10,10,true]
rline=mkpixel[31,0,0]
blank1=mkpixel[16,16,16]
blank2=mkpixel[8,8,8]
blank3=mkpixel[30,16,24]
lcol=mkpixel[ 0,20,20]
ipallet=[
  nil,
  *8.times.flat_map{|pid|
    vmgr.getspcolors(pid)[1..-1].map{|r| mkpixel[*r] }
  },
  blank1,blank2,blank3
]

tiles2file=->tiles,file,dotsize=3{
  rown=tiles.size/16
  csizeh=1024*dotsize+17
  csizev=64*rown*dotsize+rown+1
  canvas=csizev.times.flat_map{|i|
    i%(dotsize*64+1)==0 ? [lcol]*csizeh : [lcol,*[bg]*(64*dotsize)]*16+[lcol]
  }
  (rown*16).times{|i|
    t,jr,kr=tiles[i]
    r0=i/16*(dotsize*64+1)+1
    c0=i%16*(dotsize*64+1)+1
    64.times{|j|
      r=r0+j*dotsize
      64.times{|k|
        b=r*csizeh+c0+k*dotsize
        color=ipallet[t[j][k]]
        if color
          dotsize.times{|n1|
            dotsize.times{|n2|
              canvas[b+csizeh*n1+n2]=color
            }
          }
        end
        canvas[b]=rline if j==jr || k==kr
      }
    }
  }
  img=Magick::Image.new(csizeh,csizev)
  img.store_pixels(0,0,csizeh,csizev,canvas)
  img.write(file)
}

sptiles=vmgr.get4bpptiles8(0)
# 314(クラブ・バー),315(プロローグ),335(エピローグ)
sptiles_ex=[314,315,335].map{|i|
  vmgr.get4bpptiles8(i)
}

gettile=->tid,pid,eid,quad{
  canvas=quad ? 16.times.map{[0]*16} : 8.times.map{[0]*8}
  settile_s=->tid,pid,eid,xoff,yoff{
    t=(448...480)===tid ? sptiles_ex[eid][tid-448] : sptiles[tid]
    8.times{|y| 8.times{|x|
      c=t[y][x]
      canvas[yoff+y][xoff+x]=pid*15+c if c>0
    } }
  }
  settile_s[tid,pid,eid,0,0]
  if quad
    settile_s[tid+1,pid,eid,8,0]
    settile_s[tid+16,pid,eid,0,8]
    settile_s[tid+17,pid,eid,8,8]
  end
  canvas
}

geteid=->cgid,pid{
  return 2 if pid>=194 || cgid==9
  return 1 if cgid==8 || cgid==11 || cgid>=19
  return 1 if cgid==10 && pid==139
  return 1 if cgid==12 && pid>=144
  return 1 if cgid==15 && pid>=186
  return 0
}
# 64,64 
pmgr=PartsMgr.new(romobj)
PartsMgr::CGID_RANGE.each{|cgid|
  ptab = pmgr.getpaddrtab(cgid)
  pidmax=ptab.keys.max
  bpartss=(121..123).map{|px| [[[[px]*64]*64,-1,-1]] }
  ps=(
    cgid>=25 ?
      [[0,pidmax+1],[1,(-pidmax-1)%16]] :
    pidmax>=192 ?
      [[0,176],[2,16],[0,16],[2,16],[0,pidmax-191],[1,(-pidmax-1)%16]] :
      [[0,176],[2,16],[0,pidmax-175],[1,(-pidmax-1)%16],[2,16]]
  ).reduce([]){|s,(i,n)| s+bpartss[i]*n }
  ptab.each{|pid,(bank,addr)|
    dids=[nil]
    if (168...177)===pid
      dids << (cgid*9+pid-168)
    elsif (177...186)===pid
      dids << (cgid*9+pid+48)
    end
    dids.each{|did|
      xi,xs,yi,ys,parts=pmgr.getparts(bank,addr,did)
      xi=0 if xi>0
      yi=0 if yi>0
      xs=0 if xs<0
      ys=0 if ys<0
      xbase=(64-xs-xi)/2
      ybase=ys-yi>64 ? 62-ys : (64-ys-yi)/2
      itile=64.times.map{[0]*64}
      eid=geteid[cgid,pid]
      parts.each{|part|
        tile=gettile[part.tid,part.pid,eid,part.quad]
        x,y=part.x+xbase,part.y+ybase
        (part.quad ? 16 : 8).times{|dy|
          next if dy+y<0
          dyc=part.vrev ? (part.quad ? 15 : 7)-dy : dy
          (part.quad ? 16 : 8).times{|dx|
            next if itile[y+dy][x+dx]!=0
            dxc=part.hrev ? (part.quad ? 15 : 7)-dx : dx
            itile[y+dy][x+dx]=tile[dyc][dxc]
          }
        }
      }
      pid_c=pid+(pid<176 ? 0 : pid<192 ? 16 : 32)+(did ? 16 : 0)
      ps[pid_c]=[itile,ybase,xbase]
    }
  }
  tiles2file[ps,"pose-%02d.png"%cgid]
} 


