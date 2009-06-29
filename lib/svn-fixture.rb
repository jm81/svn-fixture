require "fileutils"
require "tmpdir"
require "date"
require "time"
# Subversion Ruby bindings must be installed (see README)
require "svn/core"
require "svn/fs"
require "svn/repos"

module SvnFixture
  class << self
    # Return time string formatted as expected by ::Svn::Client::Context#propset
    # (example 2009-06-28T12:00:00.000000Z). If +val+ does not respond to 
    # +strftime+, val will first be parsed via +Time.parse+.
    def svn_time(val)
      val = Time.parse(val) unless val.respond_to?(:strftime)
      val.strftime("%Y-%m-%dT%H:%M:%S.000000Z")
    end
    
    def repo(name, repos_path = nil, &block)
      r = SvnFixture::Repository.get(name, repos_path)
      r.instance_eval(&block) if block_given?
      r
    end
  end
end

# Require classes
%w{ repository revision directory file }.each do |file|
  require File.dirname(__FILE__) + '/svn-fixture/' + file
end
