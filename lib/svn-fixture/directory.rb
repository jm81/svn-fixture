module SvnFixture
  # A Directory to be added to or edited within the Repository. Normally, this 
  # would br done through Directory#dir, in a block given to a Directory or
  # Revision, for example:
  #
  #     SvnFixture.repo('repo_name') do
  #       revision(1, 'msg') do
  #         dir('test-dir') do
  #           prop('name', 'value')
  #           file('file.txt')
  #         end
  #       end
  #     end
  #
  # In that case, Revision takes care of passing the +ctx+ argument.
  # 
  # To call SvnFixture::Directory.new directly, you will need to set up a 
  # context (instance of Svn::Client::Context) and check out a working copy. 
  # +SvnFixture.simple_context+ is a quick method for settin up a Context.
  #
  # Assuming an existing checked out working copy:
  #
  #     ctx = SvnFixture.simple_context
  #     d = SvnFixture::Directory.new(ctx, '/full/fs/path/to/dir')
  #     d.prop('propname', 'Value')
  #
  # Or, call #checkout on Context:
  #
  #     ctx = SvnFixture.simple_context
  #     ctx.checkout('file:///repository/uri', '/fs/path/of/wc')
  #     d = SvnFixture::Directory.new(ctx, '/fs/path/of/wc/to/dir')
  #     d.prop('propname', 'Value')
  class Directory
    
    # +new+ is normally called through Directory#dir (a block to a Revision is
    # applied to the root Directory).
    #
    # Arguments are:
    # - +ctx+: An Svn::Client::Context, normally from Repository#ctx
    # - +path+: The path (on the file system) of the Directory in the working 
    #   copy.
    def initialize(ctx, path)
      @ctx  = ctx
      @path = path
      @path += "/" unless path[-1] == 47
    end
    
    # Create or access a subdirectory. Takes the name of the subdirectory (not a
    # full path) and an optional block with the subdirectory as self.
    def dir(name, &block)
      path = @path + name
      unless ::File.directory?(path)
        FileUtils.mkdir_p(path)
        @ctx.add(path)
      end
      d = self.class.new(@ctx, path)
      d.instance_eval(&block) if block_given?
      d
    end
    
    # Create or access a subdirectory. Takes the name of the file (not a
    # full path) and an optional block with the File as self.
    def file(name, &block)
      path = @path + name
      unless ::File.file?(path)
        FileUtils.touch(path)
        @ctx.add(path)
      end
      f = File.new(@ctx, path)
      f.instance_eval(&block) if block_given?
      f
    end
    
    # Move a File or Directory. From should be an existing node. From and to can
    # be any relative path below the directory.
    def move(from, to)
      @ctx.mv(@path + from, @path + to)
    end

    # Copy a File or Directory. From should be an existing node. From and to can
    # be any relative path below the directory.
    def copy(from, to)
      @ctx.cp(@path + from, @path + to)
    end
    
    # Delete (and remove from Repository) a child node.
    def delete(name)
      @ctx.delete(@path + name)
    end
    
    # Set a property for the Directory
    # (see http://svnbook.red-bean.com/en/1.1/ch07s02.html):
    #
    # ==== Parameters
    # name<String>:: The property name (must be "human-readable text")
    # value<String>:: The value of the property.
    # recurse<True, False>:: Apply this property to descendants?
    def prop(name, value, recurse = false)
      @ctx.propset(name, SvnFixture.svn_prop(value), @path[0..-2], recurse)
    end
    
    # Remove a property from the directory
    #
    # ==== Parameters
    # name<String>:: The property name
    def propdel(name)
      @ctx.propdel(name, @path[0..-2])
    end
  end
end
