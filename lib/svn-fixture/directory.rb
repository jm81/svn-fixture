module SvnFixture
  class Directory
    def initialize(ctx, path)
      @ctx  = ctx
      @path = path + "/"
    end
    
    def dir(name, &block)
      path = @path + name
      unless ::File.directory?(path)
        FileUtils.mkdir_p(path)
        @ctx.add(path)
      end
      d = Directory.new(@ctx, path)
      d.instance_eval(&block) if block_given?
    end
    
    def file(name, &block)
      path = @path + name
      unless ::File.file?(path)
        FileUtils.touch(path)
        @ctx.add(path)
      end
      f = File.new(@ctx, path)
      f.instance_eval(&block) if block_given?
    end
    
    def move(from, to)
      @ctx.mv(@path + from, @path + to)
    end
    
    def copy(from, to)
      @ctx.cp(@path + from, @path + to)
    end
    
    def delete(name)
      @ctx.delete(@path + name)
    end
    
    def prop(name, value)
      @ctx.propset(name, SvnFixture.svn_prop(value), @path[0..-2])
    end
  end  
end
