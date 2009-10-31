require 'spec_helper'

describe SvnFixture::File do
  before(:all) do
    @klass = SvnFixture::File
    SvnFixture::Repository.destroy_all
    
    # Set up repo
    @repos = SvnFixture::repo('file_test') do
      revision(1, 'create file') do
        file('test.txt')
      end
    end
    @repos.commit
    @repos_path = @repos.instance_variable_get(:@repos_path)
    @wc_path = @repos.instance_variable_get(:@wc_path)
    @ctx = @repos.ctx
  end
  
  before(:each) do
    @path = File.join(@wc_path, 'test.txt')
    @full_repos_path = "file://#{File.join(@repos_path, 'test.txt')}"
    @file = @node = @klass.new(@ctx, @path)
  end
  
  after(:all) do
    SvnFixture::Repository.destroy_all
  end
  
  it_should_behave_like "nodes with properties"
  
  describe '#initialize' do
    it 'should set ctx and path' do
      file = @klass.new(@ctx, '/tmp/path')
      file.instance_variable_get(:@ctx).should == @ctx
      file.instance_variable_get(:@path).should == '/tmp/path'
    end
  end
  
  describe '#body' do
    it "should update the File's contents" do
      @file.body('Test Content')
      File.read(@path).should == 'Test Content'
    end
  end
end
