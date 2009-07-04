module SvnFixture
  # A File to be added to or edited within the Repository. Normally, this would 
  # done through Directory#file, in a block given to a Directory or
  # Revision, for example:
  #
  #     SvnFixture.repo('repo_name') do
  #       revision(1, 'msg') do
  #         file('file.txt') do
  #           prop('name', 'value')
  #           body('Some Text')
  #         end
  #       end
  #     end
  #
  # In that case, Revision takes care of passing the +ctx+ argument.
  # 
  # To call SvnFixture::File.new directly, you will need to set up a context
  # (instance of Svn::Client::Context) and check out a working copy. 
  # +SvnFixture.simple_context+ is a quick method for settin up a Context.
  #
  # Assuming an existing checked out working copy:
  #
  #     ctx = SvnFixture.simple_context
  #     f = SvnFixture::File.new(ctx, '/full/fs/path/to/file.txt')
  #     f.prop('propname', 'Value')
  #
  # Or, call #checkout on Context:
  #
  #     ctx = SvnFixture.simple_context
  #     ctx.checkout('file:///repository/uri', '/fs/path/of/wc')
  #     f = SvnFixture::File.new(ctx, '/full/fs/path/to/file.txt')
  #     f.prop('propname', 'Value')
  class File
    
    # +new+ is normally called through Directory#file (a block to a Revision is
    # applied to the root Directory).
    #
    # Arguments are:
    # - +ctx+: An Svn::Client::Context, normally from Repository#ctx
    # - +path+: The path (on the file system) of the File in the working copy
    def initialize(ctx, path)
      @ctx, @path = ctx, path
    end
    
    # Set a property for the file
    # (see http://svnbook.red-bean.com/en/1.1/ch07s02.html):
    # - +name+: The property name (must be "human-readable text")
    # - +value+: The value of the property.
    def prop(name, value)
      @ctx.propset(name, SvnFixture.svn_prop(value), @path)
    end
    
    # Set the content of a file
    def body(val)
      ::File.open(@path, 'w') { |f| f.write(val) }
    end
  end
end
