module SvnFixture
  # A Revision of the Repository. It can be added via Repository#revision to
  # a specific Repository
  #
  #     repo = SvnFixture::Repository.get('test') do
  #       revision(1, 'log msg')
  #     end
  #     repo.commit
  #
  # or specified in Repository#commit:
  #
  #     rev = SvnFixture::Revision.new(1, 'log msg')
  #     SvnFixture::Repository.get('test').commit(rev)
  class Revision
    attr_reader :name
    
    # Initialize a Revision (normally called by Repository#revision).
    #
    # - +name+: A name of the Revision, can be given in Array to 
    #   Repository#commit instead of the Revision itself. Can be a revision
    #   number, but this does not affect the actual revision number in the
    #   Subversion repository.
    # - +message+: Log message. Defaults to empty String.
    # - +options+:
    #   - +:author+: The Revision's author
    #   - +:date+: The date and time of the commit
    # - Optionally accepts a block. The block, if given, is run at the time
    #   #commit is called, within the context of the root directory of the
    #   Repository, which is an instance of SvnFixture::Directory. For example:
    #
    #     SvnFixture::Revision.new(1, 'log msg') do
    #       dir('test') # Or any other SvnFixture::Directory instance method.
    #     end
    def initialize(name, message = "", options = {}, &block)
      @name, @message, @block = name, message, block
      @author = options.delete(:author)
      @date = SvnFixture.svn_time(options.delete(:date))
    end
    
    # Processes the changes made in this revision. Normally these would be made
    # in a block given to Revision.new. #commit runs that block against the root
    # directory of the working copy. This method is usually called by
    # Repository#commit instead of directly. Also sets Revision properties for
    # log message and, optionally, author and date, based on arguments 
    # to +.new+. If there are no changes, the commit fails and a warning to that
    # effect.
    # 
    # Only argument is an instance of SvnFixture::Repository that is the
    # Repository to which this revision is committed.
    def commit(repo)
      root = Directory.new(repo.ctx, repo.wc_path)
      root.instance_eval(&@block) if @block
      ci = repo.ctx.ci(repo.wc_path)
      unless ci.revision == Svn::Core::INVALID_REVNUM
        rev = ci.revision
        repo.repos.fs.set_prop('svn:log', @message, rev) if @message
        repo.repos.fs.set_prop('svn:author', @author, rev) if @author
        repo.repos.fs.set_prop('svn:date', @date, rev) if @date
      else
        puts "Warning: No change in revision #{name} (SvnFixture::Revision#commit)"
      end
      return true
    end
  end
end
