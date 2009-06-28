require "fileutils"
require "svn/core"
require "svn/fs"
require "svn/repos"

module SvnFixture

  def self.svn_time(val)
    if val.respond_to?(:strftime)
      return val.strftime("%Y-%m-%dT%H:%M:%S.000000Z")
    end
    return val
  end

  def self.repo(name, repos_path = nil, &block)
    r = SvnFixture::Repository.get(name, repos_path)
    r.instance_eval(&block) if block_given?
    r
  end

end

# Require classes
%w{ repository revision directory file }.each do |file|
  require File.dirname(__FILE__) + '/svn-fixture/' + file
end
