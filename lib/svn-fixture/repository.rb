module SvnFixture
  # Repository sets up the repository and is reponsible for checkouts and 
  # the actual commit(s). No actual work is done until +commit+ is called.
  class Repository   
    attr_reader :repos, :ctx, :wc_path, :revisions
    
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
      
      # Remove all Repositories from +.repositories+ and delete repos and 
      # working copy directories. Useful to call upon completion of tests.
      def destroy_all
        repositories.each {|name, repo| repo.destroy}
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
      if self.class.repositories[name]
        raise RuntimeError, "A Repository with this name (#{@name}) already exists."
      end
      
      @repos_path = repos_path || ::File.join(SvnFixture::config[:base_path], "repo_#{name}")
      @wc_path    = wc_path    || ::File.join(SvnFixture::config[:base_path], "wc_#{name}")
      check_paths_available
      @revisions = []
      @dirs_created = [] # Keep track of any directories created for use by #destroy
      self.class.repositories[name] = self
      self.instance_eval(&block) if block_given?
    end
    
    # Add a Revision to this Repository. +name+ and +msg+ are required.
    # - +name+: A name (or number of Revision). This is used in informational
    #   messages only.
    # - +msg+: Log message for the revision.
    # - +options+: :author and :date Revision properties.
    # - Accepts a block that is processed by Revision#commit within a Directory
    #   instance (the root directory at this revision). See +Directory+ for
    #   more information.
    def revision(name, msg, options = {}, &block)
      r = Revision.new(name, msg, options, &block)
      @revisions << r
      r
    end
    
    # Create the Subversion repository. This is called by #checkout unless 
    # something already exists at @repos_path. It can also be called directly.
    # This allows the flexibility of doing some work between creating the 
    # Repository and running checkout or commit (although I've yet to think of
    # what that work would be), or creating the repository some other way.
    def create
      FileUtils.mkdir_p(@repos_path)
      @dirs_created << @repos_path
      ::Svn::Repos.create(@repos_path)
      self
    end

    # Checkout a working copy, and setup context. This is call by #commit unless
    # something already exists at @wc_path. It can also be called directly.
    # This allows the flexibility of doing some work between checking out the 
    # Repository and commit, or checking out some other way. Also, calls #create
    # if needed.
    def checkout
      create unless ::File.exist?(@repos_path)
      @repos = ::Svn::Repos.open(@repos_path)
      @repos_uri = "file://" + ::File.expand_path(@repos_path)
      FileUtils.mkdir_p(@wc_path)
      @dirs_created << @wc_path
      @ctx = SvnFixture::simple_context
      @ctx.checkout(@repos_uri, @wc_path)
      self
    end
    
    # Commit actually commits the changes of the revisions. It accepts an 
    # optional Array of Revisions or Revision names. Otherwise, it commits all
    # revisions. If +to_commit+ is an Array of revisions (not revision names),
    # they do not need to be explicitly part of this Repository (that is, they
    # do not need to have been created through self#revision)
    # 
    #     repos.commit # Commits all Revisions added through self#revision
    #     repos.commit([1,2,4]) # Commits Revisions named 1, 2, and 4, added through self#revision
    #     repos.commit([rev1, rev3]) # Assuming rev1 and rev3 are instances of
    #                                # SvnFixture::Revision, commits them
    #                                # whether or not they were added through self#revision
    #
    # A Revision can be added to the revisions Array directly:
    #
    #     repos.revisions << Revision.new(1, 'msg')
    def commit(to_commit = nil)
      checkout unless ::File.exist?(@wc_path)
      to_commit = @revisions if to_commit.nil?
      to_commit = [to_commit] if (!to_commit.respond_to?(:each) || to_commit.kind_of?(String))
      
      to_commit.each do | rev |
        rev = @revisions.find{ |r| r.name == rev } unless rev.kind_of?(Revision)
        rev.commit(self)
      end
    end
    
    # Remove Repository from +.repositories+ and delete repos and working copy
    # directories.
    def destroy
      @dirs_created.each { |d| FileUtils.rm_rf(d) }
      self.class.repositories.delete(@name)
    end
    
    private

    # Check if either @repos_path or @wc_path exist. Called by #initialize.
    def check_paths_available
      if ::File.exist?(@repos_path)
        raise RuntimeError, "repos_path already exists (#{@repos_path})"
      elsif ::File.exist?(@wc_path)
        raise RuntimeError, "wc_path already exists (#{@wc_path})"
      end
    end
  end
end
