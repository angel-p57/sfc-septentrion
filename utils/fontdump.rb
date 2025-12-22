require_relative('lib/romutl')
require_relative('lib/vramutl')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

[57,296,297,298,334].each{|i|
  puts "** vdata #{i} **"
  tiles=vmgr.get2bpptiles16(i)
  tiles.each_slice(8).with_index{|st,j|
    puts "* #{j*8} - #{j*8+7} *"
    16.times{|k|
      puts ?|+st.map{|tile|
        tile[k].join.tr(?0,?\s)
      }.join(?|)+?|
    }
  }
}
