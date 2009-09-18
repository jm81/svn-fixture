require 'spec_helper'

describe "SvnFixture.config" do
  before(:each) do
    # Force to default state
    SvnFixture.instance_variable_set(:@config, nil)
  end
  
  after(:all) do
    # Force to default state for other specs
    SvnFixture.instance_variable_set(:@config, nil)
  end
  
  it 'should initialize with CONFIG_DEFAULTS' do
    SvnFixture.config.should == SvnFixture::CONFIG_DEFAULTS
  end
  
  it 'should be writable' do
    SvnFixture.config[:base_path] = '/tmp/elsewhere'
    SvnFixture.instance_variable_get(:@config)[:base_path].
        should == '/tmp/elsewhere'
  end
  
  describe ':base_path' do
    it 'should default to "#{Dir.tmpdir)/#{svn-fixture}"' do
      SvnFixture.config[:base_path].should == File.join(Dir.tmpdir, 'svn-fixture')
    end
  end
end
