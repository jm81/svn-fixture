svn-fixture
===========

svn-fixture simplifies creating (or updating) a Subversion repository. It is
designed to be used in tests that require a Subversion repo, but can also be
used to initialize a repository according to some template. svn-fixture depends
on the Subversion Ruby bindings (see below for Installation help).

##Usage

svn-fixture uses blocks to mimic the structure of the Repository, in the 
hierarchy: Repository -> Revision -> Directory tree structure with 
subdirectories and files. For example:

    SvnFixture::repo('hello_world') do
      revision(1, 'Create directories',
          :author => 'jmorgan',
          :date => Time.parse('2009-01-01 12:00:00Z')) do
        dir 'app'
        dir 'docs'
        dir 'lib'
      end
      
      revision 2, 'Add a file' do
        dir 'app' do
          file 'hello.rb' do
            prop 'is_ruby', 'Yes'
            body 'puts "Hello World"'
          end
        end
      end
    end
    
    SvnFixture::repo('hello_world').commit
    
See spec/svn-fixture/fixtures/hello_world.rb and 
spec/svn-fixture/integration_spec.rb for a more complete example.

Each Repository is given a name ('hello_world' in the example above), so it can
be reopened multiple times. Repository#revision defines a new Revision. It
requires a name--but only for informational purposes--and a log message. A
Revision also accepts an options Hash including optional :author and :date
revision properties.

Within a Revision is a directory tree, specifying only **changes** in that
Revision. See Directory and File classes for details on available methods.

To actually (optionally) create the repository and make the changes and commits
specified in the Revision blocks, call Repository#commit. See Repository class
for finer tuned control over the create/checkout/commit process.

##Installation

Install Subversion Swig bindings for Ruby. Some distros have a package for this.
In debian: sudo apt-get install libsvn-ruby . See 
[https://bssvnbrowser.bountysource.com/docs/subversion_ruby_bindings](https://bssvnbrowser.bountysource.com/docs/subversion_ruby_bindings) or
[http://svn.collab.net/repos/svn/trunk/subversion/bindings/swig/INSTALL](http://svn.collab.net/repos/svn/trunk/subversion/bindings/swig/INSTALL)
for more information.

To install the gem:

    gem sources -a http://gems.github.com
    sudo gem install jm81-svn-fixture
    
To require:

    gem 'jm81-svn-fixture'
    require 'svn-fixture'

Note: This library could work using the svn command line client instead. I use
the bindings regularly, so using them makes sense for me. However, if you want
to be able to use svn-fixture without installing the bindings, please send an
email to jmorgan at morgancreative dot net, and I'll give it a shot.

##Copyright

Copyright (c) 2009 Jared Morgan. See LICENSE for details.
