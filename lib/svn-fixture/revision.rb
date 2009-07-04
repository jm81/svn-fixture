module SvnFixture
  class Revision
    attr_reader :name
    
    def initialize(name, message = "", options = {}, &block)
      @name, @message, @block = name, message, block
      @author = options.delete(:author)
      @time = SvnFixture.svn_time(options.delete(:date))
    end
    
    def commit(repo)
      root = Directory.new(repo.ctx, repo.wc_path)
      root.instance_eval(&@block)
      ci = repo.ctx.ci(repo.wc_path)
      if ci # Ensure something changed
        rev = ci.revision
        repo.repos.fs.set_prop('svn:log', @message, rev) if @message
        repo.repos.fs.set_prop('svn:author', @author, rev) if @author
        repo.repos.fs.set_prop('svn:date', @time, rev) if @time
      else
        puts "Warning: No change in revision #{name} (SvnFixture::Revision#commit)"
      end
      return true
    end
  end
end
