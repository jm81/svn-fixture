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
    @file = @klass.new(@ctx, @path)
  end
  
  after(:all) do
    SvnFixture::Repository.destroy_all
  end
  
  describe '#initialize' do
    it 'should set ctx and path' do
      file = @klass.new(@ctx, '/tmp/path')
      file.instance_variable_get(:@ctx).should == @ctx
      file.instance_variable_get(:@path).should == '/tmp/path'
    end
  end
  
  describe '#prop' do    
    it 'should set a property' do
      @file.prop('prop:name', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      
      @file.prop('prop:name', 'New Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'New Value'
    end
    
    it 'should format a Time correctly' do
      @file.prop('prop:timeval', Time.parse('2009-06-18 14:00 UTC'))
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:timeval', @path, rev)[@full_repos_path].should ==
          '2009-06-18T14:00:00.000000Z'
    end
  end
  
  describe '#body' do
    it "should update the File's contents" do
      @file.body('Test Content')
      File.read(@path).should == 'Test Content'
    end
  end
end
