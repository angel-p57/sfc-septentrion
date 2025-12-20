require_relative('lib/romutl')
require_relative('lib/msgutl')
require_relative('lib/evutl')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
msgs_all={}
mcats={?a=>'7x'}
%W(c r l j p).each{|c|
  msgs=msgs_all[c]=[]
  cmgr=ChunkManager.new(romobj,c)
  mcats[c]=cmgr.msgcat
  cmgr.idrange.each{|cid|
    chunk=cmgr.get(cid)
    (chunk.mnum-1).times{|i|
      (msgs[chunk.mid+i]||=[]).push("%03d-%02d,next___" % [cid,i+1])
    }
    (msgs[chunk.mid+chunk.mnum-1]||=[]).push(
      ("%03d-%02d," % [cid,chunk.mnum]) + (
        chunk.doans ?
          chunk.ansn>0 ?
            "%03d,%03d" % [chunk.ansp,chunk.ansn] :
            "%03d,end" % chunk.ansp : 
          chunk.ansn>0 ?
            "___,%03d" % chunk.ansn :
            "____end"
      )
    )
  }
}
msgs_all[?a]=msgs_all[?c]
#
emgr=EventManager.new(romobj)
hfull={
  ?c=>'cap', ?r=>'red', ?l=>'luk', ?j=>'jef', ?p=>'pro', ?a=>'all',
}
EventManager::EVID_RANGE.each{|evid|
  event=emgr.get(evid)
  if not event
    puts "%03d(invalid or empty)" % evid
    puts ""
    next
  end
  hero=event.hero || ?a
  puts ("%03d(%02x,%04x): %s(s=%s), %s%s" % [
    evid,event.bank,event.addr,
    event.raw ? 'raw' : 'unc',
    event.raw ? event.msize.to_s : [event.msize,event.rsize]*?,,
    hfull[hero],
    event.rej ? ' (rej)' : ''
  ])
  schars = event.chars.map{|cid|
    cid&0x80>0 ? "%d(*)"%(cid&0x7f) : cid.to_s
  }
  rchunks = event.rchunks.map{|cid| (cid||?-).to_s }
  puts " char ids: #{schars*?,} ( r:#{event.rnum} )"
  puts " msgidbase: #{event.msgid_base}, chunkidbase: #{event.cid_base}"
  puts " startchunk: "+(event.cid_start||?-).to_s+", readychunks: "+(rchunks*?,)
  event.pos.each_with_index{|r,i|
    puts " pos#{i}: "+(r ? r.map{|(x,y)|"(0x%03x,0x%03x)"%[x,y]}*?, : ?-)
  }
  mcat=mcats[hero]
  puts " commands:"
  event.cmds.each.with_index(3){|r,i|
    cmds = r.map{|r2| r2.map{|b| "%03d" % b }*?, }*'  '
    if i==3
      puts "  030:__________init___________:  #{cmds}"
    else
      mid=event.msgid_base+i-2
      msgs=msgs_all[hero][mid]
      if msgs
        msgs.each{|msg|
          puts "  %02x0:%s-%s(%s-%04d):  %s" % [i, hero, msg, mcat, mid, cmds]
        }
      else
        puts "  %02x0:-------------------(%s-%04d):  %s" % [i, mcat, mid, cmds]
      end
    end
  }
  puts ""
}
