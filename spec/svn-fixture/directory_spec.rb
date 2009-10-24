require 'spec_helper'

describe SvnFixture::Directory do
  before(:each) do
    @klass = SvnFixture::Directory
    SvnFixture::Repository.destroy_all
    
    # Set up repo
    @repos = SvnFixture::repo('dir_test') do
      revision(1, 'create directory and file') do
        dir('test-dir') do
          dir('subdir')
          file('file.txt')
        end
      end
    end
    @repos.commit
    @repos_path = @repos.instance_variable_get(:@repos_path)
    @wc_path = @repos.instance_variable_get(:@wc_path)
    @ctx = @repos.ctx
  end
  
  before(:each) do
    @path = File.join(@wc_path, 'test-dir')
    @full_repos_path = "file://#{File.join(@repos_path, 'test-dir')}"
    @dir = @klass.new(@ctx, @path)
  end
  
  after(:all) do
    SvnFixture::Repository.destroy_all
  end
  
  describe '#initialize' do
    it 'should set ctx and path' do
      dir = @klass.new(@ctx, '/tmp/path/')
      dir.instance_variable_get(:@ctx).should == @ctx
      dir.instance_variable_get(:@path).should == '/tmp/path/'
    end
    
    it 'should add a trailing slash to path if needed' do
      dir = @klass.new(@ctx, '/tmp/path')
      dir.instance_variable_get(:@path).should == '/tmp/path/'
    end
  end
  
  describe '#dir' do
    before(:each) do
      @subdir_path = File.join(@path, 'subdir')
    end
    
    it 'should create a new directory if needed (and add to Subversion)' do
      new_path = File.join(@path, 'subdir2')
      File.exist?(new_path).should be_false
      new_dir = @dir.dir('subdir2')
      @ctx.commit(@wc_path)
      File.exist?(new_path).should be_true
      @repos.repos.fs.root.dir?('test-dir/subdir2').should be_true
    end
    
    it 'should use an existing directory' do
      FileUtils.should_not_receive(:mkdir_p)
      @ctx.should_not_receive(:add)
      @dir.dir('subdir')
    end
    
    it 'should setup a new SvnFixture::Directory' do
      SvnFixture::Directory.should_receive(:new).with(@ctx, @subdir_path)
      @dir.dir('subdir')
    end
    
    it 'should return the Directory' do
      sub = @dir.dir('subdir')
      sub.should be_kind_of(SvnFixture::Directory)
      sub.instance_variable_get(:@path).should == @subdir_path + '/'
    end
    
    it 'should run block if given' do
      SvnFixture::File.should_receive(:new).with(@ctx, File.join(@subdir_path, 'test.txt'))
      @dir.dir('subdir') do
        file('test.txt')
      end
    end
  end
  
  describe '#file' do
    before(:each) do
      @file_path = File.join(@path, 'file.txt')
    end
    
    it 'should create a new file if needed (and add to Subversion)' do
      new_path = File.join(@path, 'file2.txt')
      File.exist?(new_path).should be_false
      f = @dir.file('file2.txt')
      @ctx.commit(@wc_path)
      File.exist?(new_path).should be_true
      @repos.repos.fs.root.file?('test-dir/file2.txt').should be_true
    end
    
    it 'should use an existing file' do
      FileUtils.should_not_receive(:touch)
      @ctx.should_not_receive(:add)
      @dir.file('file.txt')
    end
    
    it 'should setup a new SvnFixture::File' do
      SvnFixture::File.should_receive(:new).with(@ctx, @file_path)
      @dir.file('file.txt')
    end
    
    it 'should return the File' do
      f = @dir.file('file.txt')
      f.should be_kind_of(SvnFixture::File)
      f.instance_variable_get(:@path).should == @file_path
    end
    
    it 'should run block if given' do
      @dir.file('file.txt') do
        body('Test')
      end
      File.read(@file_path).should == 'Test'
    end
  end
  
  describe '#move' do
    before(:each) do
      @file_path = File.join(@path, 'file.txt')
    end
    
    it 'should move node in FS and Subversion' do
      new_path = File.join(@path, 'subdir', 'file2.txt')
      File.exist?(new_path).should be_false
      File.exist?(@file_path).should be_true
      @dir.move('file.txt', 'subdir/file2.txt')
      File.exist?(new_path).should be_true
      File.exist?(@file_path).should be_false
      @ctx.commit(@wc_path)
      @repos.repos.fs.root.file?('test-dir/file.txt').should be_false
      @repos.repos.fs.root.file?('test-dir/subdir/file2.txt').should be_true
    end
  end
  
  describe '#copy' do
    before(:each) do
      @file_path = File.join(@path, 'file.txt')
    end
    
    it 'should copy node in FS and Subversion' do
      new_path = File.join(@path, 'subdir', 'file2.txt')
      File.exist?(new_path).should be_false
      File.exist?(@file_path).should be_true
      @dir.copy('file.txt', 'subdir/file2.txt')
      File.exist?(new_path).should be_true
      File.exist?(@file_path).should be_true
      @ctx.commit(@wc_path)
      @repos.repos.fs.root.file?('test-dir/file.txt').should be_true
      @repos.repos.fs.root.file?('test-dir/subdir/file2.txt').should be_true
    end
  end
  
  describe '#delete' do
    before(:each) do
      @file_path = File.join(@path, 'file.txt')
    end
    
    it 'should copy node in FS and Subversion' do
      File.exist?(@file_path).should be_true
      @dir.delete('file.txt')
      File.exist?(@file_path).should be_false
      @ctx.commit(@wc_path)
      @repos.repos.fs.root.file?('test-dir/file.txt').should be_false
    end
  end
  
  describe '#prop' do    
    it 'should set a property' do
      @dir.prop('prop:name', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      
      @dir.prop('prop:name', 'New Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'New Value'
    end
    
    it 'should not set a property recursively by default' do
      @dir.prop('prop:name', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      @ctx.propget('prop:name', @path + "/subdir", rev)[@full_repos_path + "/subdir"].should be_nil
      @ctx.propget('prop:name', @path + "/file.txt", rev)[@full_repos_path + "/file.txt"].should be_nil
    end
    
    it 'should set a property recursively if told to' do
      @dir.prop('prop:name', 'Prop Value', true)
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      @ctx.propget('prop:name', @path + "/subdir", rev)[@full_repos_path + "/subdir"].should ==
          'Prop Value'
      @ctx.propget('prop:name', @path + "/file.txt", rev)[@full_repos_path + "/file.txt"].should ==
          'Prop Value'
    end
    
    it 'should format a Time correctly' do
      @dir.prop('prop:timeval', Time.parse('2009-06-18 14:00 UTC'))
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:timeval', @path, rev)[@full_repos_path].should ==
          '2009-06-18T14:00:00.000000Z'
    end
  end
  
  describe '#propdel' do    
    it 'should delete a property' do
      @dir.prop('prop:del', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:del', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      
      @dir.propdel('prop:del')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:del', @path, rev)[@full_repos_path].should be_nil
    end
  end
end
