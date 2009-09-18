require 'spec_helper'

# Test again fixtures/hello_world.rb to follow a complete fixture generation.
describe 'SvnFixture integration' do
  before(:all) do
    SvnFixture::Repository.instance_variable_set(:@repositories, {})
    load File.dirname(__FILE__) + '/fixtures/hello_world.rb'
    SvnFixture::repo('hello_world').commit
    repos_path = File.join(Dir.tmpdir, 'svn-fixture', 'repo_hello_world')
    @repos = ::Svn::Repos.open(repos_path)
    @fs = @repos.fs
  end
  
  after(:all) do
    SvnFixture::Repository.destroy_all
  end
  
  describe 'revision 1' do
    before(:each) do
      @root = @fs.root(1)
    end
    
    it 'should have 3 directories' do
      @root.dir?('app').should be_true
      @root.dir?('docs').should be_true
      @root.dir?('lib').should be_true
    end
    
    it 'should not have files' do
      @root.file?('app/hello.rb').should be_false
    end
    
    it 'should have specified date at rev 1' do
      @fs.prop(Svn::Core::PROP_REVISION_DATE, 1).should ==
          Time.parse('2009-01-01 12:00:00Z')
    end
  end
  
  describe 'revision 2' do
    before(:each) do
      @root = @fs.root(2)
    end
    
    it 'should have files' do
      @root.file?('app/hello.rb').should be_true
      @root.file_contents('app/hello.rb') do |f|
        f.read.should == 'puts "Hello World"'
      end
      @root.file?('app/goodbye.rb').should be_true
    end
    
    it 'should have property for hello.rb' do
      @root.node_proplist('app/hello.rb')['is_ruby'].should == 'Yes'
    end
  end
  
  describe 'revision 3' do
    before(:each) do
      @root = @fs.root(3)
    end
    
    it 'should change text for hello.rb' do
      @root.file_contents('app/hello.rb') do |f|
        f.read.should == 'puts "Howdy World"'
      end
    end
    
    it 'should change property for hello.rb' do
      @root.node_proplist('app/hello.rb')['is_ruby'].should == 'Probably'
    end
    
    it 'should set author' do
      @fs.prop(Svn::Core::PROP_REVISION_AUTHOR, 3).should ==
          'the.author'
    end
  end
  
  describe 'revision 4' do
    before(:each) do
      @root = @fs.root(4)
    end
    
    it 'should copy/move files' do
      @root.file?('app/hello.rb').should be_true
      @root.file?('app/hello2.rb').should be_true
      @root.file_contents('app/hello2.rb') do |f|
        f.read.should == 'puts "Howdy World"'
      end
      @root.file?('app/goodbye.rb').should be_false
      @root.file?('app/bye.rb').should be_true
    end
    
    it 'should have expected dirs, files' do
      @root.dir?('app').should be_true
      @root.file?('app/hello.rb').should be_true
      @root.file?('app/hello2.rb').should be_true
      @root.file?('app/bye.rb').should be_true
      @root.dir?('docs').should be_true
      @root.dir?('lib').should be_true
    end
  end
end
