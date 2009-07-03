require File.dirname(__FILE__) + '/../spec_helper'

describe SvnFixture::Repository do
  before(:all) do
    @klass = SvnFixture::Repository
  end
  
  before(:each) do
    # Force to default state
    @klass.instance_variable_set(:@repositories, {})
  end
  
  after(:all) do
    # Force to default state for other specs
    @klass.instance_variable_set(:@repositories, {})
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
    it 'needs tests'
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
    it 'needs tests'
  end
  
  describe '.destroy_all' do
    it 'needs tests'
  end
end
