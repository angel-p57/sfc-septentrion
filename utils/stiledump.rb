require_relative('lib/romutl')
require_relative('lib/vramutl')

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
vmgr=VRAMmgr.new(romobj)

[0,4].each{|i|
  puts "** vdata #{i} **"
  tiles=vmgr.get4bpptiles8(i)
  tiles.each_slice(16).with_index{|st,j|
    puts "* #{j*16} - #{j*16+15} *"
    8.times{|k|
      puts ?|+st.map{|tile|
        tile[k].map{|x| x==0 ? ?\s : x.to_s(16) }.join
      }.join(?|)+?|
    }
  }
}
