require_relative('lib/romutl')
require_relative('lib/msgutl')
romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
%W(c r l j p).each{|c|
  cmgr=ChunkManager.new(romobj,c)
  mmgr=MsgManager.new(romobj,cmgr.msgcat)
  cmgr.idrange.each{|cid|
    chunk=cmgr.get(cid)
    header="%s-%03d(%02x,%04x)" % [c,cid,cmgr.bank,chunk.addr]
    ansinfo=chunk.doans ?
      chunk.ansn>0 ?
        "A,%03d,%03d" % [chunk.ansp,chunk.ansn] :
        "A,%03d,___" % chunk.ansp : 
      chunk.ansn>0 ?
        "N,___,%03d" % chunk.ansn :
        "N,___,___"
    msgidrange = chunk.mid .. chunk.mid+chunk.mnum-1
    rangeinfo="%04d-%04d"%[msgidrange.first, msgidrange.last]
    puts "#{header}: #{ansinfo} : #{rangeinfo} : " + msgidrange.map{|mid| ?"+mmgr.get(mid)[0]+?" }.join(' -> ')
  }
}
