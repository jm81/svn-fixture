module SvnFixture
  class Repository
    @@repositories = {}
    BASE_PATH = ::File.dirname(__FILE__) + "/tmp/"
    
    attr_reader :repos, :ctx, :wc_path
    
    class << self
      def get(name, repos_path)
        @@repositories[name] ||= Repository.new(name, repos_path)
      end
    end  
    
    def initialize(name, repos_path = nil)
      @name = name
      @repos_path = repos_path || (BASE_PATH + 'repo_' + name)
      @wc_path = BASE_PATH + 'wc_' + name
      @revisions = []
    end
    
    def revision(name, msg, options = {}, &block)
      @revisions << Revision.new(self, name, msg, options, &block)
    end
    
    # Partly based on setup_repository method from
    # http://svn.collab.net/repos/svn/trunk/subversion/bindings/swig/ruby/test/util.rb
    def create
      FileUtils.rm_rf(@repos_path)
      FileUtils.mkdir_p(@repos_path)
      ::Svn::Repos.create(@repos_path)

      checkout
    end

    # Setup context and working copy
    def checkout
      @repos = ::Svn::Repos.open(@repos_path)
      @repos_uri = "file://" + ::File.expand_path(@repos_path)
      FileUtils.rm_rf(@wc_path)        
      FileUtils.mkdir_p(@wc_path)  
      @ctx = ::Svn::Client::Context.new
 
      # I don't understand the auth_baton and log_baton, so I set them here,
      # then use revision properties.
      @ctx.add_username_prompt_provider(0) do |cred, realm, username, may_save|
         cred.username = "ANON"
      end
      @ctx.set_log_msg_func {|items| [true, ""]}
      
      @ctx.checkout(@repos_uri, @wc_path)
      self
    end

    def commit(to_commit = nil)
      to_commit = @revisions if to_commit.nil?
      to_commit = [to_commit] if (!to_commit.respond_to?(:each) || to_commit.kind_of?(String))
      
      to_commit.each do | rev |
        rev = @revisions.find{ |r| r.name == rev } unless rev.kind_of?(Revision)
        rev.commit
      end
    end
    
  end
end
