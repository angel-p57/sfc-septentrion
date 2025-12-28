require 'set'
require_relative('lib/romutl')
require_relative('lib/msgutl')
require_relative('lib/evutl')

class EvFlow
  def list_move(state)
    return %W(ans noans) if state[?a]>0
    return %W(msg) if state[?n]>0
    return state.keys.select{|k|
      if state[k]==0
        false
      elsif k[0]==?y
        true
      elsif k[0]==?x
        c=k[1..-1].to_i
        if !@dead[c]
          true
        elsif @done.include?(c)
          false
        else
          @done << c
          true
        end
      else
        false
      end
    }
  end
  def initialize(romobj,event,dead,en4)
    @cmgr=ChunkManager.new(romobj,event.hero)
    @dead=dead.dup
    @done=Set.new
    @istate=event.chars.zip(event.rchunks).each_with_object({}){|(c,r),h| h["x#{c&0x3f}"]=r||0 }
    @istate[?a]=0
    @istate[?n]=event.cid_start ? event.cid_start : 0
    @msgidbase=event.msgid_base
    @cidbase=event.cid_base
    @commands=event.cmds
    self.apply_commands(0, @istate, en4)
    @istate[?n]=@istate.delete(?e) if en4 && @istate[?e]
  end
  attr_reader :istate
  def apply_commands(off, state, en4)
    ret=nil
    @commands[off].reverse_each{|command|
      case command[0]
      when 3
        state["x#{command[1]}"]=command[2]==0 ? 0 : @cidbase+command[2]
      when 4
        if command[2]!=255
          if !en4
            state["ea"]=1
          else
            state[?e]=@cidbase+command[2]
          end
        end
      when 129
        if command[2]==128
          state.delete_if{|k,v| k[0]===?y }
          state["y#{command[3]}"]=@cidbase+command[1] if command[3]!=0
        end
      when 192
        if (command[1]==0 || command[1]==255) && (command[2]==0 || command[2]==255)
          state[?f]=1
          (ret||=[]) << ?f
        end
      when 193
        rc="r#{command[1]}"
        state["x#{command[1]}"]=0
        state[rc]=1
        state[?f]=1
        (ret||=[]) << rc
        ret << ?f
      when 194
        state["x#{command[1]}"]||=0
        (ret||=[]) << "m#{command[1]}"
      end
    }
    ret
  end
  def apply_move(move, state, en4)
    ret=nil
    case move
    when "ans"
      raise "no doans for ans" if state[?a]==0
      state[?n]=state[?a]
      state[?a]=0
    when "noans"
      raise "no doans for noans" if state[?a]==0
      state[?a]=0
    when "msg"
      ea=state["ea"]
      cid=state[?n]
      c=@cmgr.get(cid)
      cid_int=nil
      change=[]
      c.mnum.times{|cid_s|
        mid=c.mid+cid_s
        off=mid-@msgidbase-1
        unless (1...@commands.size)===off
          change << "or"
          next
        end
        cret=apply_commands(off,state,en4)
        change.push(*cret) if cret
        if en4 && state[?e]
          cid_int=cid_s+1
          break
        end
      }
      change=change.sort.uniq
      if cid_int
        change.unshift("s#{cid_int}") if cid_int<c.mnum
        change.unshift("ex")
        state[?a]=0
        state[?n]=state.delete(?e) or raise
      else
        change.unshift("ea") if !ea&&state["ea"]
        state[?a]=c.doans ? c.ansp : 0
        state[?n]=c.ansn
      end
      ret=[ "c%03d"%cid, *change ].join(?,)
    else
      if move[0]==?y
        state[?n]=state.delete(move) or raise
      else
        state[?n]=state[move] or raise
      end
    end
    ret
  end
end

romfile=ARGV[0]||SepRom::DEFAULT_ROM_PATH
romobj=SepRom.new(romfile)
emgr=EventManager.new(romobj)

getflow=->evid{
  event=emgr.get(evid) or return nil
  return nil if event.rej
  hero=event.hero
  dead_chars = event.chars.flat_map{|c|
    c&0x80>0 ? [c&0x3f] : []
  }
  flows=(
    dead_chars.empty? ?  [false] : [true, false]
  ).each_with_object([]){|short,ret|
    dead=event.chars.each_with_object({}){|c,h|
      h[c&0x3f]=short && c&0x80>0
    }
    [false,true].each{|en4|
      ea=false
      ef=EvFlow.new(romobj,event,dead,en4)
      state=ef.istate.dup
      stnum=0
      stcheck={state=>stnum}
      stcache=[state]
      q=ef.list_move(state).each_with_object([]){|m,q|
        q << [0,m]
      }
      nodes={0=>{}}
      until q.empty?
        si,m=q.pop
        sn=stcache[si].dup
        r=ef.apply_move(m,sn,en4)
        si2=stcheck[sn]
        if !si2
          ea=true if state["ea"]
          si2=stcheck[sn]=stnum+=1
          nodes[si2]={}
          stcache[si2]=sn
          ef.list_move(sn).each{|m|
            q << [si2,m]
          }
        end
        (nodes[si][si2]||=[])<<(r||m)
      end
      nodes.values.each{|h| h.values.each{|r| r.sort! } }
      loop {
        convtab={}
        nodes.keys.sort_by{|k| nodes[k].hash }.chunk{|k| nodes[k] }.each{|_,r|
          next if r.size<=1
          rmin=r.min
          r.each{|k|
            next if k==rmin
            convtab[k]=rmin
          }
        }
        break if convtab.empty?
        nodes=nodes.each_with_object({}){|(k,r),h|
          next if convtab[k]
          h[k]=r.each_with_object({}){|(s,m),h2| h2[convtab[s]||s]=m }
        }
      }
      nodes.each{|s,r|
        r.keys.each{|s2| r[s2]=r[s2].join(?|)}
      }
      tmp={}
      nodes.each{|s,r|
        r.each{|(s2,m)|
          tmp[s2]=(tmp[s2]||0)+((nodes[s2].values[0]||"x")[0]==?c ? 1 : 2)
        }
      }
      ni=0
      ct={}
      nodes.keys.each{|i|
        next if i!=0&&tmp[i]&&tmp[i]==1
        ct[i]=ni
        ni+=1
      }
      ret << [
        short,
        en4,
        nodes.each_with_object({}){|(s,r),h|
          next if s!=0&&tmp[s]&&tmp[s]==1
          h[ct[s]]=r.each_with_object({}){|(s2,m),h2|
            ma=[m]
            while tmp[s2]&&tmp[s2]==1
              r2=nodes[s2]
              s2=r2.keys[0]
              ma << r2[s2]
            end
            (h2[ct[s2]]||=[]) << ma
          }
        }
      ]
      break unless ea
    }
  }
  [hero, dead_chars, flows]
}
showflow1=->nodes{
  lnum=0
  nodes.each{|s,r|
    r.each{|(s2,ms)|
      ms.each{|m|
        puts "#{s} -> #{s2} ( #{m.join(?*)} )"
        lnum+=1
      }
    }
  }
  puts "(#{lnum})"
  puts ""
}
showflow2=->nodes,hero{
  ncnts=[1]
  nodes.each{|s1,v|
    v.each{|s2,r|
      ncnts[s2]=(ncnts[s2]||0)+1
    }
  }
  stmp=0
  sconv=ncnts.each_with_index.with_object({}){|(nc,s1),h|
    next if nc<2
    h[s1]="s#{stmp}"
    stmp+=1
  }
  cmgr=ChunkManager.new(romobj,hero)
  mmgr=MsgManager.new(romobj,cmgr.msgcat)
  getmsgs=->mp{
    chunk=cmgr.get(mp[1,3].to_i)
    sid=mp[/(?<=,s)\d+/]
    (chunk.mid ... chunk.mid+(sid ? sid.to_i : chunk.mnum )).map{|mid|
      ?"+mmgr.get(mid)[0]+?"
    }.join(' -> ')
  }
  scheck=Set.new
  dorec=->s,d=0{
    node=nodes[s]
    return  [(" "*d)+"(e)"] if node.size==0
    init=[]
    if sconv[s]
      return [(" "*(d>0 ? d-1 : d))+" >#{sconv[s]}"] if scheck.include?(s)
      init << ((" "*d)+"(#{sconv[s]})")
      scheck << s
    end
    msgonly=node.values[0][0][0][0]==?c
    [ *init,
      *node.keys.sort.reverse_each.map{|s2|
        node[s2].sort_by{|m| m[0] }.reduce([]){|sum,m|
          d2 = msgonly ? d : d+1
          m.each_with_index.flat_map{|mp,i|
            !msgonly && i==0 ?
              [(" "*d)+?*+mp] :
              [" "*d2+hero+?-+mp[1..-1], " "*d2+getmsgs[mp]]
          } + dorec[s2, d2] + sum
        }
      }.reverse
    ]
  }
  dorec[0].each{|line| puts line }
}
(0...128).each{|evid|
  ret=getflow[evid] or next
  hero,dead,flows=ret
  puts "*** state trans for #{evid} ( dead=#{dead.empty? ? 'none' : dead.join(?,)} ) ***"
  flows.each{|(short,en4,nodes)|
    puts "** #{short ? 'short ' : ''}#{en4 ? 'with' : 'without'} ex **"
#    showflow1[nodes]
    showflow2[nodes,hero]
  }
}
