require_relative('lib/romutl')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
SepRom::BANK_RANGE.each{|bank|
  chunksize=0x10
  SepRom::ADDRESS_RANGE.first.step(SepRom::ADDRESS_RANGE.last, chunksize){|addr|
    chunk=romobj.getbytes(bank,addr,chunksize)
    puts "%02x,%04x: %s" % [
      bank,
      addr,
      chunk.each_slice(2).map{|(x,y)| "%02x%02x" % [x,y] }.join(' ')
    ]
  }
}
