require 'spec_helper'

describe SvnFixture do
  
  describe '.svn_time' do
    it 'should format as expected by ::Svn::Client::Context#propset' do
      t = Time.parse('2009-06-18 13:00 UTC')
      SvnFixture.svn_time(t).should == '2009-06-18T13:00:00.000000Z'
      
      d = Date.parse('2009-06-19')
      SvnFixture.svn_time(d).should == '2009-06-19T00:00:00.000000Z'
    end
    
    it 'should parse the #to_s value if not a Date or Time or nil' do
      t = '2009-06-18 13:00:01.002 UTC'
      SvnFixture.svn_time(t).should == '2009-06-18T13:00:01.002000Z'
    end
    
    it 'should return nil if value is nil' do
      SvnFixture.svn_time(nil).should be_nil
    end
  end
  
  describe '.svn_prop' do
    it 'should format Time/Date as expected by ::Svn::Client::Context#propset' do
      t = Time.parse('2009-06-18 13:00:01.002111 UTC')
      SvnFixture.svn_prop(t).should == '2009-06-18T13:00:01.002111Z'
      
      d = Date.parse('2009-06-19')
      SvnFixture.svn_prop(d).should == '2009-06-19T00:00:00.000000Z'
    end
    
    it 'should leave alone non Time/Date values' do
      t = 'Test'
      SvnFixture.svn_prop(t).should == 'Test'
    end
  end
  
  describe '.repo' do
    it 'should call Repository.get' do
      SvnFixture::Repository.should_receive(:get).with('test', '/tmp/repos_test', 'tmp/wc')
      SvnFixture.repo('test', '/tmp/repos_test', 'tmp/wc')
    end
  end
  
  describe '.simple_context' do
    before(:each) do
      SvnFixture::Repository.destroy_all
      @repos = SvnFixture.repo('test').create
      @repos_path = @repos.instance_variable_get(:@repos_path)
      @wc_path = @repos.instance_variable_get(:@wc_path)
      @path = File.join(@wc_path, 'file.txt')
      @full_repos_path = "file://#{File.join(@repos_path, 'file.txt')}"
    end
    
    after(:each) do
      FileUtils.rm_rf(@wc_path)
    end
    
    after(:all) do
      SvnFixture::Repository.destroy_all
    end
    
    def add_prop_to_file
      FileUtils.touch(@path)
      @ctx.add(@path)
      file = SvnFixture::File.new(@ctx, @path)
      file.prop('name', 'Value')
      @ctx.commit(@wc_path)
      @ctx.propget('name', @path)[@full_repos_path].should == 'Value'
    end
    
    it 'should return a Context' do
      SvnFixture.simple_context.should be_kind_of(::Svn::Client::Context)
    end
    
    it 'should be useable by File/Directory with a working copy checked out' do
      @repos.checkout # Checkout under different context (although same setup)
      @ctx = SvnFixture.simple_context
      add_prop_to_file
    end
    
    it 'should be useable to checkout a working copy' do
      @ctx = SvnFixture.simple_context
      @ctx.checkout("file://" + ::File.expand_path(@repos_path), @wc_path)
      add_prop_to_file
    end
  end
end
