require_relative('lib/romutl')
require_relative('lib/msgutl')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
MsgManager::CATS.each{|cat|
  mmgr=MsgManager.new(romobj,cat)
  mmgr.idrange.each{|i|
    msg,bank,addr,rawdata=mmgr.get(i)
    puts "%s-%04d(%02x,%04x): %s ( %s )" % [
      cat,
      i,
      bank,
      addr,
      msg,
      rawdata.map{|b| "%02x" % b }.join(',')
    ]
  }
}
