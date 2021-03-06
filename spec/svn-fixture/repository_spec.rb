require 'spec_helper'

describe SvnFixture::Repository do
  before(:all) do
    @klass = SvnFixture::Repository
  end
  
  before(:each) do
    # Force to default state
    @klass.destroy_all
  end
  
  after(:all) do
    # Force to default state for other specs
    @klass.destroy_all
  end
  
  describe '.get' do
    it 'should create a new repository if not found' do
      @klass.instance_variable_get(:@repositories).should be_empty
      r0 = @klass.get('test')
      r0.should be_kind_of(SvnFixture::Repository)
      
      r1 = @klass.get('different')
      r0.should_not be(r1)
    end
    
    it 'should get an existing repository' do
      @klass.instance_variable_get(:@repositories).should be_empty
      r0 = @klass.new('test')
      r1 = @klass.get('test')
      r0.should be(r1)
    end
    
    it 'should pass repos_path and wc_path to .new' do
      @klass.should_receive(:new).with('test', '/tmp/repo', '/tmp/wc')
      @klass.get('test', '/tmp/repo', '/tmp/wc')
    end
    
    it 'should pass block to .new' do
      # There's probably a better way to test this
      SvnFixture::Revision.should_receive(:new).twice
      @klass.get('test') do
        revision(1, 'log')
        revision(2, 'log')
      end
    end
    
    it 'should process a block for an existing Repository' do
      @klass.new('test')
      SvnFixture::Revision.should_receive(:new).twice
      @klass.get('test') do
        revision(1, 'log')
        revision(2, 'log')
      end
    end
  end
  
  describe '.repositories' do
    it 'should default to an empty Hash' do
      @klass.repositories.should == {}
    end
  end
  
  describe '.new' do
    it 'should add to .repositories' do
      @klass.repositories.should be_empty
      r = @klass.new('new_repo')
      @klass.repositories.should == {'new_repo' => r}
    end
    
    it 'should evaluate block if given' do
      SvnFixture::Revision.should_receive(:new).once
      @klass.new('test') do
        revision(1, 'log')
      end
    end
    
    it "should verify there's no other Repository with this name" do
      @klass.new('test')
      lambda { @klass.new('test') }.should raise_error(
          RuntimeError, "A Repository with this name (test) already exists.")
    end
    
    it 'should set up @repos_path' do
      r = @klass.new('test1', '/test/path')
      r.instance_variable_get(:@repos_path).should == '/test/path'

      r = @klass.new('test2')
      r.instance_variable_get(:@repos_path).should == 
          ::File.join(SvnFixture::config[:base_path], 'repo_test2')
    end
    
    it 'should set up @wc_path' do
      r = @klass.new('test1', nil, '/test/path')
      r.instance_variable_get(:@wc_path).should == '/test/path'

      r = @klass.new('test2')
      r.instance_variable_get(:@wc_path).should == 
          ::File.join(SvnFixture::config[:base_path], 'wc_test2')
    end
    
    it 'should initialize an empty revisions Array' do
      r = @klass.new('test')
      r.instance_variable_get(:@revisions).should == []
    end
    
    it 'should verify that repos_path does not exist' do
      repos_path = File.join(Dir.tmpdir, 'svn-fixture-test-path')
      FileUtils.mkdir_p(repos_path)
      lambda {
        @klass.new('test', repos_path, File.join(Dir.tmpdir, 'other-test-path'))
      }.should raise_error(RuntimeError, "repos_path already exists (#{repos_path})")
    end
    
    it 'should verify that wc_path does not exist' do
      File.exist?(File.join(Dir.tmpdir, 'other-test-path')).should be_false
      wc_path = File.join(Dir.tmpdir, 'svn-fixture-test-path')
      FileUtils.mkdir_p(wc_path)
      lambda {
        @klass.new('test', File.join(Dir.tmpdir, 'other-test-path'), wc_path)
      }.should raise_error(RuntimeError, "wc_path already exists (#{wc_path})")
    end
  end
  
  describe '#revision' do
    before(:each) do
      @repos = @klass.new('test')
    end
    
    it 'should create a Revision' do
      SvnFixture::Revision.should_receive(:new).with(1, 'log msg', {})
      @repos.revision(1, 'log msg', {})
    end
    
    it 'should add Revision to @revisions' do
      @repos.instance_variable_get(:@revisions).should == []
      rev1 = @repos.revision(1, 'log msg', {})
      rev2 = @repos.revision(2, 'log msg', {})
      @repos.instance_variable_get(:@revisions).should == [rev1, rev2]
    end
    
    it 'should accept a block' do
      rev = @repos.revision(1, 'log msg', {}) do
        dir('whatever')
      end
      rev.instance_variable_get(:@block).should be_kind_of(Proc)
    end
  end
  
  describe '@revisions' do
    it 'can be updated directly' do
      @repos = @klass.new('test')
      @repos.revisions.should == []
      rev = SvnFixture::Revision.new(1, 'msg')
      @repos.revisions << rev
      @repos.instance_variable_get(:@revisions).should == [rev]
    end
  end

  describe '#create' do
    before(:each) do
      @repos = @klass.new('test')
      @repos_path = @repos.instance_variable_get(:@repos_path)
    end
    
    it 'should create Subversion repository' do
      ::Svn::Repos.should_receive(:create).with(@repos_path)
      @repos.create
    end
    
    it 'should create at repos_path' do
      File.exist?(@repos_path).should be_false
      @repos.create
      File.exist?(@repos_path).should be_true
      @repos.instance_variable_get(:@dirs_created).should == [@repos_path]
    end
    
    it 'should return self (for method chaining)' do
      @repos.create.should be(@repos)
    end
  end
  
  describe '#checkout' do
    before(:each) do
      @repos = @klass.new('test')
      @repos_path = @repos.instance_variable_get(:@repos_path)
      @wc_path = @repos.instance_variable_get(:@wc_path)
    end
    
    it 'should call #create if needed' do
      File.exist?(@repos_path).should be_false
      @repos.checkout
      File.exist?(@repos_path).should be_true
      @repos.instance_variable_get(:@dirs_created).should include(@repos_path)
    end
    
    it 'should call not call #create if something exists at @repos_path' do
      FileUtils.mkdir_p(@repos_path)
      ::Svn::Repos.create(@repos_path)
      @repos.should_not_receive(:create)
      @repos.checkout
      FileUtils.rm_rf(@repos_path)
    end
    
    it 'should create @ctx (Svn::Client::Context)' do
      @repos.ctx.should be_nil
      @repos.checkout
      @repos.ctx.should be_kind_of(::Svn::Client::Context)
    end
    
    it 'should checkout repository at wc_path' do
      File.exist?(@wc_path).should be_false
      @repos.checkout
      File.exist?(@wc_path).should be_true
      File.exist?(File.join(@wc_path, '.svn')).should be_true
      @repos.instance_variable_get(:@dirs_created).should include(@wc_path)
    end
    
    it 'should return self' do
      @repos.checkout.should be(@repos)
    end
  end
  
  describe '#commit' do
    before(:each) do
      @repos = @klass.new('test') do
        revision(1, 'log') do
          dir 'test-dir'
        end
        
        revision(2, 'log') do
          file 'test-file.txt'
        end
        
        revision(3, 'log') do
          file 'test-file2.txt'
        end
      end
      @repos_path = @repos.instance_variable_get(:@repos_path)
      @wc_path = @repos.instance_variable_get(:@wc_path)
    end
    
    it 'should call #checkout if needed' do
      File.exist?(@wc_path).should be_false
      @repos.commit
      File.exist?(@wc_path).should be_true
      @repos.instance_variable_get(:@dirs_created).should include(@wc_path)
    end
    
    it 'should call not call #checkout if something exists at @wc_path' do
      @repos.checkout
      File.exist?(@wc_path).should be_true
      @repos.should_not_receive(:checkout)
      @repos.commit
    end
    
    it 'should commit all Revisions if no arguments given' do
      @repos.revisions[0].should_receive(:commit).with(@repos)
      @repos.revisions[1].should_receive(:commit).with(@repos)
      @repos.revisions[2].should_receive(:commit).with(@repos)
      @repos.commit
    end
    
    it 'should commit Revisions by name and/or actual instance' do
      @repos.revisions[0].should_receive(:commit).with(@repos)
      @repos.revisions[2].should_receive(:commit).with(@repos)
      @repos.commit(@repos.revisions[2], 1)
    end
  end
  
  describe '#destroy' do
    before(:each) do
      @repos = @klass.new('test')
    end
    
    it 'should delete repository and working copy directories' do
      repos_path = @repos.instance_variable_get(:@repos_path)
      wc_path    = @repos.instance_variable_get(:@wc_path)
      @repos.checkout # To create directories
      
      File.exist?(repos_path).should be_true
      File.exist?(wc_path).should be_true
      
      @repos.destroy
      
      File.exist?(repos_path).should be_false
      File.exist?(wc_path).should be_false
    end
    
    it 'should not destroy directories that the Repository did not make' do
      repos_path = @repos.instance_variable_get(:@repos_path)
      wc_path    = @repos.instance_variable_get(:@wc_path)
      FileUtils.mkdir_p(repos_path)
      FileUtils.mkdir_p(wc_path)
      
      @repos.destroy
      
      File.exist?(repos_path).should be_true
      File.exist?(wc_path).should be_true
      
      # Remove for other tests
      FileUtils.rm_rf(repos_path)
      FileUtils.rm_rf(wc_path)
    end
    
    it 'should remove Repository from .repositories' do
      @klass.repositories.should == {'test' => @repos}
      @repos.destroy
      @klass.repositories.should == {}
    end
    
    it 'should not remove other Repositories' do
      other_repos = @klass.new('other')
      other_repos.checkout
      @klass.repositories.should == {'test' => @repos, 'other' => other_repos}
      @repos.destroy
      @klass.repositories.should == {'other' => other_repos}
      File.exist?(other_repos.instance_variable_get(:@repos_path)).should be_true
      File.exist?(other_repos.instance_variable_get(:@wc_path)).should be_true
    end
  end
  
  describe '#wc_path' do
    it 'should be the absolute path to the working copy' do
      r = @klass.new('test1', '/test/repos', '/test/wc')
      r.wc_path.should == '/test/wc'
    end
  end
  
  describe '#repos_path' do
    it 'should be the absolute path to the repository' do
      r = @klass.new('test1', '/test/repos', '/test/wc')
      r.repos_path.should == '/test/repos'
    end
  end
  
  describe '#uri' do
    it 'should return the uri for accessing the Repository' do
      r = @klass.new('test1', '/test/path')
      r.uri.should == 'file:///test/path'
    end
  end
  
  describe '.destroy_all' do
    it 'should destroy all Repositories' do
      repos = [@klass.new('test1'), @klass.new('test2'), @klass.new('test3')]
      repos.each {|repo| repo.should_receive(:destroy)}
      @klass.destroy_all
    end
    
    it 'should empty .repositories Hash' do
      repos = [@klass.new('test1'), @klass.new('test2'), @klass.new('test3')]
      @klass.destroy_all
      @klass.repositories.should == {}      
    end
  end
end
