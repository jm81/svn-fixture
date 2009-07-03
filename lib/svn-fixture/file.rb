module SvnFixture
  class File
    def initialize(ctx, path)
      @ctx, @path = ctx, path
    end
    
    def prop(name, value)
      @ctx.propset(name, SvnFixture.svn_prop(value), @path)
    end
    
    def body(val)
      ::File.open(@path, 'w') { |f| f.write(val) }
    end
  end
end
