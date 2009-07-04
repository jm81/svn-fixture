module SvnFixture
  # A File to be added to the Repository. Normally, this would done through
  # Revison#file (or Directory#file), in a block, for example:
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
  class File
    
    # +new+ is normally called through Revison#file (or Directory#file).
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
