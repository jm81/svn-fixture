require "fileutils"
require "tmpdir"
require "date"
require "time"
# Subversion Ruby bindings must be installed (see README)
require "svn/core"
require "svn/fs"
require "svn/repos"

module SvnFixture
  VERSION = '0.2.0'
  
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
      val = val.utc if val.respond_to?(:utc)
      usec = val.respond_to?(:usec) ? val.usec : 0
      val.strftime("%Y-%m-%dT%H:%M:%S.") + sprintf('%06dZ', usec)
    end
    
    # Return a Date or Time formatted as expected by 
    # ::Svn::Client::Context#propset (see +svn_time+); leave other values alone.
    def svn_prop(val)
      val.respond_to?(:strftime) ? svn_time(val) : val
    end
    
    # .repo is just a shortcut to +SvnFixture::Repository.get+
    def repo(*args, &block)
      SvnFixture::Repository.get(*args, &block)
    end
    
    # Setup and return a simple ::Svn::Client::Context. This is called by
    # Repository#checkout, but can also be used in called Directory.new or 
    # File.new directly. See SvnFixture::File for examples.
    def simple_context
      ctx = ::Svn::Client::Context.new
 
      # I don't understand the auth_baton and log_baton, so I set them here,
      # then use revision properties.
      ctx.add_username_prompt_provider(0) do |cred, realm, username, may_save|
         cred.username = "ANON"
      end
      ctx.set_log_msg_func {|items| [true, ""]}
      ctx
    end
  end
end

if defined?(Merb::Plugins)
  # Make config accessible through Merb's Merb::Plugins.config hash
  Merb::Plugins.config[:svn_fixture] = SvnFixture.config
end

require 'svn-fixture/repository'
require 'svn-fixture/revision'
require 'svn-fixture/directory'
require 'svn-fixture/file'
