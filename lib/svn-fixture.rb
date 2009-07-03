require "fileutils"
require "tmpdir"
require "date"
require "time"
# Subversion Ruby bindings must be installed (see README)
require "svn/core"
require "svn/fs"
require "svn/repos"

module SvnFixture
  CONFIG_DEFAULTS = {
    :base_path => File.join(Dir.tmpdir, 'svn-fixture')
  }
  
  class << self
    # SvnFixture::config method returns Hash that can be edited.
    # The only current option is
    # +:base_path+ : The path at which repositories are created. It default
    # to the OS tmp directory, plus "svn-fixture". For example, 
    # "/tmp/svn-fixture". The repo name is then appended in 
    # +SvnFixture::Repository+.
    def config
      @config ||= CONFIG_DEFAULTS.dup
    end
    
    # Return time string formatted as expected by ::Svn::Client::Context#propset
    # (example 2009-06-28T12:00:00.000000Z). If +val+ does not respond to 
    # +strftime+, val will first be parsed via +Time.parse+.
    def svn_time(val)
      return nil if val.nil?
      val = Time.parse(val) unless val.respond_to?(:strftime)
      val.strftime("%Y-%m-%dT%H:%M:%S.000000Z")
    end
    
    # Return a Date or Time formatted as expected by 
    # ::Svn::Client::Context#propset (see +svn_time+); leave other values alone.
    def svn_prop(val)
      val.respond_to?(:strftime) ? svn_time(val) : val
    end
    
    def repo(name, repos_path = nil, &block)
      r = SvnFixture::Repository.get(name, repos_path)
      r.instance_eval(&block) if block_given?
      r
    end
  end
end

if defined?(Merb::Plugins)
  # Make config accessible through Merb's Merb::Plugins.config hash
  Merb::Plugins.config[:svn_fixture] = SvnFixture.config
end

# Require classes
%w{ repository revision directory file }.each do |file|
  require File.dirname(__FILE__) + '/svn-fixture/' + file
end
