shared_examples_for "nodes with properties" do
  describe '#prop' do
    it 'should set a property' do
      @node.prop('prop:name', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      
      @node.prop('prop:name', 'New Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should ==
          'New Value'
    end
    
    it 'should format a Time correctly' do
      @node.prop('prop:timeval', Time.parse('2009-06-18 14:00 UTC'))
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:timeval', @path, rev)[@full_repos_path].should ==
          '2009-06-18T14:00:00.000000Z'
    end
  end
  
  describe '#props' do
    it 'should set properties (deleting those not included)' do
      @node.props('prop:name' => 'One', 'prop:two' => 'Two')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should == 'One'
      @ctx.propget('prop:two', @path, rev)[@full_repos_path].should == 'Two'
      
      @node.props('prop:two' => 'Two', 'prop:three' => 'Three')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:two', @path, rev)[@full_repos_path].should == 'Two'
      @ctx.propget('prop:three', @path, rev)[@full_repos_path].should == 'Three'
      @ctx.propget('prop:name', @path, rev)[@full_repos_path].should be_nil
    end
    
    it 'should ignore svn:entry properties' do
      @node.should_receive(:prop).with('prop:name', 'One')
      @node.props('prop:name' => 'One')
      @node.should_not_receive(:prop).with('svn:entry:time', 'One')
      @node.props('svn:entry:time' => 'One')
    end
  end
  
  describe '#propdel' do    
    it 'should delete a property' do
      @node.prop('prop:del', 'Prop Value')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:del', @path, rev)[@full_repos_path].should ==
          'Prop Value'
      
      @node.propdel('prop:del')
      rev = @ctx.ci(@wc_path).revision
      @ctx.propget('prop:del', @path, rev)[@full_repos_path].should be_nil
    end
  end
end
