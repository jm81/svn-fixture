module SvnFixture
  class Directory
    def initialize(repo, path)
      @repo = repo
      @path = path + "/"
    end
    
    def dir(name, &block)
      path = @path + name
      unless ::File.directory?(path)
        FileUtils.mkdir_p(path)
        @repo.ctx.add(path)
      end
      d = Directory.new(@repo, path)
      d.instance_eval(&block) if block_given?
    end
    
    def file(name, &block)
      path = @path + name
      unless ::File.file?(path)
        FileUtils.touch(path)
        @repo.ctx.add(path)
      end
      f = File.new(@repo, path)
      f.instance_eval(&block) if block_given?
    end
    
    def move(from, to)
      @repo.ctx.mv(@path + from, @path + to)
    end
    
    def copy(from, to)
      @repo.ctx.cp(@path + from, @path + to)
    end
    
    def copy_from_wistle(wistle_path)
      wistle_path = ::File.expand_path(
        ::File.dirname(__FILE__) + "/../../" + wistle_path)
      path = @path + wistle_path.split("/")[-1]
      FileUtils.cp(wistle_path, path)
      @repo.ctx.add(path)
    end
    
    def delete(name)
      @repo.ctx.delete(@path + name)
    end
    
    def prop(name, value)
      @repo.ctx.propset(name, SvnFixture.svn_prop(value), @path[0..-2])
    end
  end  
end
