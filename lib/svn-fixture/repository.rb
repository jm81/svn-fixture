module SvnFixture
  # Repository sets up the repository and is reponsible for checkouts and 
  # the actual commit(s). No actual work is done until +commit+ is called.
  class Repository   
    attr_reader :repos, :ctx, :wc_path
    
    class << self      
      # Get an SvnFixture::Repository by name. If not found, it creates a new
      # one. It accepts a block which is evaluated within the Repository
      # instance. +get+ is useful for re-accessing a Repository after initially 
      # created. For example:
      #
      #     SvnFixture::Repository.get('test') do
      #       revision(1, 'log msg') ...
      #     end
      #     
      #     SvnFixture::Repository.get('test') do
      #       revision(2, 'log msg') ...
      #       revision(3, 'log msg') ...
      #     end
      #     
      #     SvnFixture::Repository.get('test').commit
      def get(name, repos_path = nil, wc_path = nil, &block)
        if repositories[name]
          repositories[name].instance_eval(&block) if block_given?
          repositories[name]
        else
          Repository.new(name, repos_path, wc_path, &block)
        end
      end
      
      # Hash of {name => Repository} of currently defined Repositories
      def repositories
        @repositories ||= {}
      end
    end
    
    # Arguments (last two are optional)
    # - +name+: The name of the repository, used by Repository.get and used in
    #   +repos_path+ and +wc_path+ if not given.
    # - +repos_path+: The path where the repository is stored (defaults to
    #   "#{config[:base_path]}/repo_#{name}"
    # - +wc_path+: The path where the working copy is checked out (defaults to
    #   "#{config[:base_path]}/wc_#{name}"
    # Note: the paths should be normal file system paths, not file:/// paths.
    #
    # +new+ also accepts a block which is evaluated within the Repository
    # instance:
    #
    #     SvnFixture::Repository.new('name') do
    #       revision(1, 'log msg') ...
    #     end
    # 
    # Otherwise, you could, for example:
    #
    #     r = SvnFixture::Repository.new('name')
    #     r.revision(1, 'log msg') do
    #       ...
    #     end
    #     r.commit
    def initialize(name, repos_path = nil, wc_path = nil, &block)
      @name = name
      @repos_path = repos_path || ::File.join(SvnFixture::config[:base_path], "repo_#{name}")
      @wc_path    = wc_path    || ::File.join(SvnFixture::config[:base_path], "wc_#{name}")
      @revisions = []
      self.class.repositories[name] = self
      self.instance_eval(&block) if block_given?
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
