require 'rmagick'

class ImgManager
  def self.mkpixel(r5,g5,b5,tp=false)
    tp ?
      Magick::Pixel.new(r5*2048, g5*2048, b5*2048, 65535) :
      Magick::Pixel.new(r5*2048, g5*2048, b5*2048)
  end
  def self.save(filename, canvas, sizeh, sizev)
    img=Magick::Image.new(sizeh,sizev)
    img.store_pixels(0,0,sizeh,sizev,canvas)
    img.write(filename)
  end
end

class TiledCanvas
  @@linecolor=ImgManager.mkpixel(0,20,20)
  @@bgcolor=ImgManager.mkpixel(10,10,10,true)
  class TileWindow
    def initialize(canvas,trow,tcol)
      @canvas=canvas
      @trow=trow
      @tcol=tcol
    end
    def []=(prow,pcol,px)
      @canvas.dsize.times{|i|
        @canvas.dsize.times{|j|
          @canvas[@trow,@tcol,prow,pcol,i,j]=px
        }
      }
    end
  end
  def initialize(tsize,dsize,rownum,colnum,sline=true)
    @slinew=sline ? 1 : 0
    @dsize=dsize
    @tsize=tsize
    @rownum=rownum
    @colnum=colnum
    @tdotnum=@tsize*@dsize+@slinew
    @vsize=@tdotnum*rownum+@slinew
    @hsize=@tdotnum*colnum+@slinew
    @pxlist=@vsize.times.flat_map{|i|
      sline ?
        i % @tdotnum == 0 ?
          [@@linecolor]*@hsize :
          [@@linecolor,*[@@bgcolor]*(@tdotnum-1)]*@colnum+[@@linecolor] :
        [@@bgcolor]*@hsize
    }
  end
  attr_reader :dsize
  def []=(trow,tcol,prow,pcol,i,j,px)
    @pxlist[(trow*@tdotnum+prow*@dsize+i+@slinew)*@hsize+tcol*@tdotnum+pcol*@dsize+j+@slinew]=px
  end
  def makewindow(trow,tcol)
    TileWindow.new(self,trow,tcol)
  end
  def save(filename)
    ImgManager.save(filename,@pxlist,@hsize,@vsize)
  end
end
