# For use by integration_spec

SvnFixture::repo('hello_world') do
  revision(1, 'Create directories',
      :date => Time.parse('2009-01-01 12:00:00Z')) do
    dir 'app'
    dir 'docs'
    dir 'lib'
  end
  
  revision 2, 'Add some files' do
    dir 'app' do
      prop 'full_name', 'Application'
      
      file 'hello.rb' do
        prop 'is_ruby', 'Yes'
        body 'puts "Hello World"'
      end
      
      file 'goodbye.rb' do
        body 'puts "Goodbye World"'
      end
    end
  end
end

SvnFixture::repo('hello_world') do
  revision 3, 'Edit hello.rb', :author => "the.author" do
    dir 'app' do
      file 'hello.rb' do
        prop 'is_ruby', 'Probably'
        body 'puts "Howdy World"'
      end
    end
  end
  
  revision 4, 'Copy and move' do
    dir 'app' do
      move 'goodbye.rb', 'bye.rb'
      copy 'hello.rb', 'hello2.rb'
    end
  end
end
