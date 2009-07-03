require File.dirname(__FILE__) + '/../spec_helper'

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
  end
  
  describe '#revision' do
    before(:each) do
      @repos = @klass.new('test')
    end
    
    it 'should create a Revision' do
      SvnFixture::Revision.should_receive(:new).with(@repos, 1, 'log msg', {})
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

  describe '#create' do
    it 'needs tests'
  end
  
  describe '#checkout' do
    it 'needs tests'
  end
  
  describe '#commit' do
    it 'needs tests'
  end
  
  describe '#destroy' do
    before(:each) do
      @repos = @klass.new('test')
    end
    
    it 'should delete repository and working copy directories' do
      repos_path = @repos.instance_variable_get(:@repos_path)
      wc_path    = @repos.instance_variable_get(:@wc_path)
      @repos.create # To create directories
      
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
      other_repos.create
      @klass.repositories.should == {'test' => @repos, 'other' => other_repos}
      @repos.destroy
      @klass.repositories.should == {'other' => other_repos}
      File.exist?(other_repos.instance_variable_get(:@repos_path)).should be_true
      File.exist?(other_repos.instance_variable_get(:@wc_path)).should be_true
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
