module SvnFixture
  class File
    def initialize(repo, path)
      @repo, @path = repo, path
    end
    
    def prop(name, value)
      @repo.ctx.propset(name, SvnFixture.svn_prop(value), @path)
    end
    
    def body(val)
      ::File.open(@path, 'w') { |f| f.write(val) }
    end
  end
end
