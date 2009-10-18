require 'spec_helper'

describe SvnFixture::Revision do
  before(:all) do
    @klass = SvnFixture::Revision
  end
  
  describe '#initialize' do
    it 'should accept a name, message, options and block' do
      rev = @klass.new('name', 'msg', {:author => 'author'}) do
        dir('test-dir')
      end
      
      rev.name.should == 'name'
      rev.instance_variable_get(:@message).should == 'msg'
      rev.instance_variable_get(:@author).should == 'author'
      rev.instance_variable_get(:@revprops).should == {}
      rev.instance_variable_get(:@block).should be_kind_of(Proc)
    end
    
    it 'should convert +:date+ option to an +svn_time+' do
      rev = SvnFixture::Revision.new('name', 'msg', {:date => Time.parse('2009-01-01 12:00:00Z')})
      rev.instance_variable_get(:@date).should == '2009-01-01T12:00:00.000000Z'
    end
  end
  
  describe 'commit' do
    before(:all) do
      @repos = SvnFixture::repo('file_test').checkout
      # @repos_path = @repos.instance_variable_get(:@repos_path)
      @wc_path = @repos.instance_variable_get(:@wc_path)
      options = {
        :author => 'author',
        :date => Time.parse('2009-01-01 12:00:00Z'),
        'other:revprop' => 20,
        'other:timeprop' => Time.parse('2009-01-01 12:00:01.0912Z')
      }
      
      @rev = @klass.new(1, 'msg', options) do
        dir('test-dir')
      end
      @rev.commit(@repos)
      @fs = @repos.repos.fs
    end
    
    after(:all) do
      SvnFixture::Repository.destroy_all
    end
    
    it 'should process @block on root directory' do
      File.exist?(File.join(@wc_path, 'test-dir')).should be_true
    end
    
    it 'should commit changes' do
      @fs.root.dir?('test-dir').should be_true
    end
    
    it 'should set log message' do
      @fs.prop(Svn::Core::PROP_REVISION_LOG, 1).should == 'msg'
    end
    
    it 'should set author if given' do
      @fs.prop(Svn::Core::PROP_REVISION_AUTHOR, 1).should == 'author'
    end
    
    it 'should set date if given' do
      @fs.prop(Svn::Core::PROP_REVISION_DATE, 1).should == 
          Time.parse('2009-01-01T12:00:00.000000Z')
    end
    
    it 'should set additional revprops if given' do
      @fs.prop('other:revprop', 1).should == '20'
      @fs.prop('other:timeprop', 1).should == '2009-01-01T12:00:01.091200Z'
    end
    
    it 'should print warning if no changes' do
      no_change_rev = @klass.new(2, 'msg')
      no_change_rev.should_receive(:puts).
          with("Warning: No change in revision 2 (SvnFixture::Revision#commit)")
      no_change_rev.commit(@repos)
    end
  end
end
