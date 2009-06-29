require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SvnFixture do
  
  describe '.svn_time' do
    it 'should format as expected by ::Svn::Client::Context#propset' do
      t = Time.parse('2009-06-18 13:00')
      SvnFixture.svn_time(t).should == '2009-06-18T13:00:00.000000Z'
      
      d = Date.parse('2009-06-19')
      SvnFixture.svn_time(d).should == '2009-06-19T00:00:00.000000Z'
    end
    
    it 'should parse the #to_s value if not a Date or Time' do
      t = '2009-06-18 13:00'
      SvnFixture.svn_time(t).should == '2009-06-18T13:00:00.000000Z'
    end
  end
end
