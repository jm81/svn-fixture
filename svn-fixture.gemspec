# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{svn-fixture}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jared Morgan"]
  s.date = %q{2009-07-05}
  s.email = %q{jmorgan@morgancreative.net}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "lib/svn-fixture.rb",
     "lib/svn-fixture/directory.rb",
     "lib/svn-fixture/file.rb",
     "lib/svn-fixture/repository.rb",
     "lib/svn-fixture/revision.rb",
     "spec/spec_helper.rb",
     "spec/svn-fixture/config_spec.rb",
     "spec/svn-fixture/directory_spec.rb",
     "spec/svn-fixture/file_spec.rb",
     "spec/svn-fixture/fixtures/hello_world.rb",
     "spec/svn-fixture/integration_spec.rb",
     "spec/svn-fixture/repository_spec.rb",
     "spec/svn-fixture/revision_spec.rb",
     "spec/svn-fixture_spec.rb",
     "svn-fixture.gemspec"
  ]
  s.homepage = %q{http://github.com/jm81/svn-fixture}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{TODO}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/svn-fixture/config_spec.rb",
     "spec/svn-fixture/directory_spec.rb",
     "spec/svn-fixture/file_spec.rb",
     "spec/svn-fixture/fixtures/hello_world.rb",
     "spec/svn-fixture/integration_spec.rb",
     "spec/svn-fixture/repository_spec.rb",
     "spec/svn-fixture/revision_spec.rb",
     "spec/svn-fixture_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
